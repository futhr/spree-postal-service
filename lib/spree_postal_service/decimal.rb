# frozen_string_literal: true

require "bigdecimal"

module SpreePostalService
  module Decimal
    module_function

    def coerce(value, name: "value")
      decimal = value.is_a?(BigDecimal) ? value : BigDecimal(value.to_s)
      raise ConfigurationError, "#{name} must be finite" unless decimal.finite?

      decimal
    rescue ArgumentError, TypeError
      raise ConfigurationError, "#{name} must be numeric"
    end
  end
end
