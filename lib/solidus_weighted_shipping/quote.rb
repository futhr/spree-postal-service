# frozen_string_literal: true

module SolidusWeightedShipping
  class Quote
    STATUSES = %i[rated free_shipping unavailable empty].freeze
    CURRENCY_PATTERN = /\A[A-Z]{3}\z/

    attr_reader :status,
      :amount,
      :currency,
      :reason,
      :chargeable_weight_in_store_units,
      :parcel_count,
      :handling_fee

    def self.rated(amount:, currency:, chargeable_weight_in_store_units:, parcel_count:, handling_fee:)
      new(
        status: :rated,
        amount:,
        currency:,
        chargeable_weight_in_store_units:,
        parcel_count:,
        handling_fee:
      )
    end

    def self.free_shipping(currency:, chargeable_weight_in_store_units:)
      new(
        status: :free_shipping,
        amount: BigDecimal("0"),
        currency:,
        chargeable_weight_in_store_units:,
        parcel_count: 0,
        handling_fee: BigDecimal("0")
      )
    end

    def self.unavailable(currency:, reason:)
      new(
        status: :unavailable,
        amount: nil,
        currency:,
        reason:,
        chargeable_weight_in_store_units: BigDecimal("0"),
        parcel_count: 0,
        handling_fee: BigDecimal("0")
      )
    end

    def self.empty(currency:)
      new(
        status: :empty,
        amount: BigDecimal("0"),
        currency:,
        chargeable_weight_in_store_units: BigDecimal("0"),
        parcel_count: 0,
        handling_fee: BigDecimal("0")
      )
    end

    def initialize(
      status:,
      amount:,
      currency:,
      chargeable_weight_in_store_units:,
      parcel_count:,
      handling_fee:,
      reason: nil
    )
      raise InputError, "unknown quote status: #{status.inspect}" unless STATUSES.include?(status)

      @status = status
      @amount = normalize_amount(amount)
      @currency = currency.to_s.strip.upcase.freeze
      raise InputError, "currency must be a three-letter code" unless CURRENCY_PATTERN.match?(@currency)

      @reason = reason
      @chargeable_weight_in_store_units = Decimal.coerce(
        chargeable_weight_in_store_units,
        name: "chargeable weight",
        error_class: InputError
      )
      if @chargeable_weight_in_store_units.negative?
        raise InputError, "chargeable weight must not be negative"
      end

      @parcel_count = normalize_parcel_count(parcel_count)
      raise InputError, "parcel count must not be negative" if @parcel_count.negative?

      @handling_fee = Decimal.coerce(handling_fee, name: "handling fee", error_class: InputError)
      raise InputError, "handling fee must not be negative" if @handling_fee.negative?
      validate_state!

      freeze
    end

    def available?
      status != :unavailable
    end

    def free_shipping?
      status == :free_shipping
    end

    private

    def normalize_amount(value)
      return nil if status == :unavailable && value.nil?

      amount = Decimal.coerce(value, name: "quote amount", error_class: InputError)
      raise InputError, "quote amount must not be negative" if amount.negative?

      amount
    end

    def normalize_parcel_count(value)
      return value if value.is_a?(Integer)

      Integer(value.to_s, 10)
    rescue ArgumentError, TypeError
      raise InputError, "parcel count must be a whole number"
    end

    def validate_state!
      if status == :unavailable
        raise InputError, "unavailable quote must include a reason" if reason.nil?
        raise InputError, "unavailable quote must not include an amount" unless amount.nil?
        return
      end

      raise InputError, "available quote must not include an unavailable reason" unless reason.nil?

      if status == :rated
        raise InputError, "rated quote must include at least one parcel" unless parcel_count.positive?
        return
      end

      unless amount.zero? && handling_fee.zero? && parcel_count.zero?
        raise InputError, "#{status} quote must have zero amount, handling fee, and parcel count"
      end
    end
  end
end
