# frozen_string_literal: true

require "bigdecimal"

module SolidusWeightedShipping
  module Decimal
    module_function

    def coerce(value, name: "value", error_class: ConfigurationError)
      raise error_class, "#{name} must use an exact decimal value" if value.is_a?(Float)

      decimal = case value
      when BigDecimal
        value
      when Rational
        BigDecimal(value.numerator) / BigDecimal(value.denominator)
      else
        BigDecimal(value.to_s)
      end

      raise error_class, "#{name} must be finite" unless decimal.finite?

      decimal
    rescue ConfigurationError, InputError
      raise
    rescue ArgumentError, TypeError
      raise error_class, "#{name} must be numeric"
    end
  end
end
