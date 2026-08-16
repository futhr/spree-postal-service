# frozen_string_literal: true

module SolidusWeightedShipping
  class RateTable
    Band = Data.define(:maximum_weight_in_store_units, :price_in_currency_units)

    Rate = Data.define(
      :amount,
      :chargeable_weight_in_store_units,
      :full_parcel_count,
      :remainder_weight_in_store_units
    ) do
      def parcel_count
        full_parcel_count + (remainder_weight_in_store_units.positive? ? 1 : 0)
      end
    end

    LINE_PATTERN = /\A([^:]+):([^:]+)\z/
    MAX_BANDS = 1_000

    attr_reader :bands

    def self.parse(value)
      unless value.is_a?(String)
        raise ConfigurationError, "rate table must be text with one 'maximum weight: price' band per line"
      end

      entries = value.lines.filter_map do |line|
        line = line.strip
        next if line.empty?

        match = LINE_PATTERN.match(line)
        unless match
          raise ConfigurationError, "rate table line must use 'maximum weight: price': #{line.inspect}"
        end

        [match[1].strip, match[2].strip]
      end

      new(bands: entries)
    end

    def self.from_legacy(thresholds:, prices:)
      thresholds = parse_legacy_sequence(thresholds, name: "weight table")
      prices = parse_legacy_sequence(prices, name: "price table")

      unless thresholds.length == prices.length
        raise ConfigurationError, "weight and price tables must contain the same number of entries"
      end

      new(bands: thresholds.zip(prices))
    end

    def self.parse_legacy_sequence(value, name:)
      values = value.is_a?(String) ? value.split : Array(value)
      raise ConfigurationError, "#{name} must not be empty" if values.empty?

      values
    end
    private_class_method :parse_legacy_sequence

    def initialize(bands:)
      @bands = Array(bands).map.with_index { |band, index| normalize_band(band, index:) }.freeze
      validate!
      freeze
    end

    def dump
      bands.map do |band|
        "#{format_decimal(band.maximum_weight_in_store_units)}: #{format_decimal(band.price_in_currency_units)}"
      end.join("\n")
    end

    def rate_for(weight)
      weight = Decimal.coerce(weight, name: "chargeable weight", error_class: InputError)
      raise InputError, "chargeable weight must not be negative" if weight.negative?

      full_parcels, remainder = weight.divmod(max_weight)
      full_parcel_count = full_parcels.to_i
      amount = maximum_price * full_parcel_count
      amount += price_for(remainder) if remainder.positive?

      Rate.new(
        amount:,
        chargeable_weight_in_store_units: weight,
        full_parcel_count:,
        remainder_weight_in_store_units: remainder
      )
    end

    def price_for(weight)
      weight = Decimal.coerce(weight, name: "parcel weight", error_class: InputError)
      raise InputError, "parcel weight must be greater than zero" unless weight.positive?
      raise InputError, "parcel weight exceeds the maximum band" if weight > max_weight

      bands.find { |band| weight <= band.maximum_weight_in_store_units }.price_in_currency_units
    end

    def max_weight
      bands.last.maximum_weight_in_store_units
    end

    def maximum_price
      bands.last.price_in_currency_units
    end

    private

    def normalize_band(value, index:)
      maximum_weight, price = case value
      when Band
        [value.maximum_weight_in_store_units, value.price_in_currency_units]
      when Hash
        [
          value[:maximum_weight] || value["maximum_weight"],
          value[:price] || value["price"]
        ]
      else
        values = Array(value)
        unless values.length == 2
          raise ConfigurationError, "band #{index + 1} must contain a maximum weight and price"
        end

        values
      end

      Band.new(
        maximum_weight_in_store_units: Decimal.coerce(maximum_weight, name: "band #{index + 1} maximum weight"),
        price_in_currency_units: Decimal.coerce(price, name: "band #{index + 1} price")
      )
    end

    def validate!
      raise ConfigurationError, "rate table must not be empty" if bands.empty?
      if bands.length > MAX_BANDS
        raise ConfigurationError, "rate table must not contain more than #{MAX_BANDS} bands"
      end

      if bands.any? { |band| !band.maximum_weight_in_store_units.positive? }
        raise ConfigurationError, "weight thresholds must be greater than zero"
      end

      if bands.each_cons(2).any? do |left, right|
        left.maximum_weight_in_store_units >= right.maximum_weight_in_store_units
      end
        raise ConfigurationError, "weight thresholds must be strictly increasing"
      end

      if bands.any? { |band| band.price_in_currency_units.negative? }
        raise ConfigurationError, "prices must not be negative"
      end
    end

    def format_decimal(value)
      value.to_s("F").sub(/\.0\z/, "")
    end
  end
end
