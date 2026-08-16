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
        from_rational(value, name:, error_class:)
      when Integer, String
        BigDecimal(value.to_s)
      else
        raise error_class, "#{name} must be numeric"
      end

      raise error_class, "#{name} must be finite" unless decimal.finite?

      decimal
    rescue ConfigurationError, InputError
      raise
    rescue ArgumentError, TypeError
      raise error_class, "#{name} must be numeric"
    end

    def from_rational(value, name:, error_class:)
      denominator = value.denominator
      powers_of_two = factor_count(denominator, 2)
      denominator >>= powers_of_two
      powers_of_five = factor_count(denominator, 5)
      denominator /= 5**powers_of_five

      unless denominator == 1
        raise error_class, "#{name} must use an exact decimal value"
      end

      scale = [powers_of_two, powers_of_five].max
      scaled_numerator = value.numerator *
        (2**(scale - powers_of_two)) *
        (5**(scale - powers_of_five))
      return BigDecimal(scaled_numerator.to_s) if scale.zero?

      sign = scaled_numerator.negative? ? "-" : ""
      digits = scaled_numerator.abs.to_s.rjust(scale + 1, "0")
      BigDecimal("#{sign}#{digits[0...-scale]}.#{digits[-scale..]}")
    end
    private_class_method :from_rational

    def factor_count(value, factor)
      count = 0
      while (value % factor).zero?
        value /= factor
        count += 1
      end
      count
    end
    private_class_method :factor_count
  end
end
