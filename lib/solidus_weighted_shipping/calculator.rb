# frozen_string_literal: true

module SolidusWeightedShipping
  class Calculator
    attr_reader :rate_table,
      :constraints,
      :free_shipping_threshold_in_currency_units,
      :handling_threshold_in_currency_units,
      :handling_fee_in_currency_units

    def initialize(
      rate_table:,
      constraints:,
      free_shipping_threshold_in_currency_units:,
      handling_threshold_in_currency_units:,
      handling_fee_in_currency_units:
    )
      unless rate_table.is_a?(RateTable)
        raise ConfigurationError, "rate table must be a SolidusWeightedShipping::RateTable value"
      end
      unless constraints.is_a?(Constraints)
        raise ConfigurationError, "constraints must be a SolidusWeightedShipping::Constraints value"
      end

      @rate_table = rate_table
      @constraints = constraints
      @free_shipping_threshold_in_currency_units = non_negative(
        free_shipping_threshold_in_currency_units,
        "free shipping threshold"
      )
      @handling_threshold_in_currency_units = non_negative(
        handling_threshold_in_currency_units,
        "handling threshold"
      )
      @handling_fee_in_currency_units = non_negative(handling_fee_in_currency_units, "handling fee")
      freeze
    end

    def available?(package)
      quote(package).available?
    end

    def quote(package)
      unless package.is_a?(PackageInput)
        raise InputError, "package must be a SolidusWeightedShipping::PackageInput value"
      end

      return Quote.empty(currency: package.currency) if package.empty?

      eligibility = constraints.package_eligibility(package)
      unless eligibility.eligible?
        return Quote.unavailable(currency: package.currency, reason: eligibility.reason)
      end

      chargeable_weight = package.total_weight(
        default_weight: constraints.default_weight_in_store_units
      )

      if package.order_merchandise_total > free_shipping_threshold_in_currency_units
        return Quote.free_shipping(
          currency: package.currency,
          chargeable_weight_in_store_units: chargeable_weight
        )
      end

      rate = rate_table.rate_for(chargeable_weight)
      handling_fee = handling_for(package)

      Quote.rated(
        amount: rate.amount + handling_fee,
        currency: package.currency,
        chargeable_weight_in_store_units: chargeable_weight,
        parcel_count: rate.parcel_count,
        handling_fee:
      )
    end

    private

    def handling_for(package)
      if package.merchandise_total <= handling_threshold_in_currency_units
        return handling_fee_in_currency_units
      end

      BigDecimal("0")
    end

    def non_negative(value, name)
      decimal = Decimal.coerce(value, name: name)
      raise ConfigurationError, "#{name} must not be negative" if decimal.negative?

      decimal
    end
  end
end
