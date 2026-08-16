# frozen_string_literal: true

module SpreePostalService
  class Calculator
    attr_reader :rate_table, :constraints, :free_shipping_threshold, :handling_threshold, :handling_fee

    def initialize(rate_table:, constraints:, free_shipping_threshold:, handling_threshold:, handling_fee:)
      @rate_table = rate_table
      @constraints = constraints
      @free_shipping_threshold = non_negative(free_shipping_threshold, "free shipping threshold")
      @handling_threshold = non_negative(handling_threshold, "handling threshold")
      @handling_fee = non_negative(handling_fee, "handling fee")
      freeze
    end

    def available?(package)
      package.items.all? { |item| constraints.item_allowed?(item) }
    end

    def quote(package)
      return BigDecimal("0") if package.order_merchandise_total > free_shipping_threshold

      shipping = rate_table.quote(package.total_weight(default_weight: constraints.default_weight))
      shipping + handling_for(package)
    end

    private

    def handling_for(package)
      return handling_fee if package.merchandise_total <= handling_threshold

      BigDecimal("0")
    end

    def non_negative(value, name)
      decimal = Decimal.coerce(value, name: name)
      raise ConfigurationError, "#{name} must not be negative" if decimal.negative?

      decimal
    end
  end
end
