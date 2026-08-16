# frozen_string_literal: true

module SpreePostalService
  class RateTable
    attr_reader :thresholds, :prices

    def initialize(thresholds:, prices:)
      @thresholds = parse_sequence(thresholds, name: "weight table")
      @prices = parse_sequence(prices, name: "price table")
      validate!
      freeze
    end

    def quote(weight)
      weight = Decimal.coerce(weight, name: "weight")
      raise ConfigurationError, "weight must not be negative" if weight.negative?
      return BigDecimal("0") if weight.zero?

      chunks, remainder = weight.divmod(max_weight)
      chunks = chunks.to_i

      if remainder.zero? && chunks.positive?
        prices.last * chunks
      else
        (prices.last * chunks) + price_for(remainder)
      end
    end

    def max_weight
      thresholds.last
    end

    private

    def price_for(weight)
      index = thresholds.index { |threshold| weight <= threshold }
      prices.fetch(index || prices.length - 1)
    end

    def parse_sequence(value, name:)
      values = value.is_a?(String) ? value.split : Array(value)
      raise ConfigurationError, "#{name} must not be empty" if values.empty?

      values.map.with_index do |entry, index|
        Decimal.coerce(entry, name: "#{name} entry #{index + 1}")
      end.freeze
    end

    def validate!
      unless thresholds.length == prices.length
        raise ConfigurationError, "weight and price tables must contain the same number of entries"
      end

      if thresholds.any?(&:negative?) || thresholds.any?(&:zero?)
        raise ConfigurationError, "weight thresholds must be greater than zero"
      end

      if thresholds.each_cons(2).any? { |left, right| left >= right }
        raise ConfigurationError, "weight thresholds must be strictly increasing"
      end

      raise ConfigurationError, "prices must not be negative" if prices.any?(&:negative?)
    end
  end
end
