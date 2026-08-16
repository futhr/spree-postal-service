# frozen_string_literal: true

module SolidusWeightedShipping
  class PackageInput
    Item = Data.define(
      :quantity,
      :unit_price_in_currency_units,
      :weight_in_store_units,
      :dimensions_in_store_units
    ) do
      def initialize(quantity:, unit_price_in_currency_units:, weight_in_store_units:, dimensions_in_store_units:)
        quantity = normalize_quantity(quantity)
        unit_price = Decimal.coerce(
          unit_price_in_currency_units,
          name: "unit price",
          error_class: InputError
        )
        raise InputError, "unit price must not be negative" if unit_price.negative?

        weight = if weight_in_store_units.nil?
          nil
        else
          Decimal.coerce(weight_in_store_units, name: "item weight", error_class: InputError)
        end

        dimensions = normalize_dimensions(dimensions_in_store_units)

        super(
          quantity:,
          unit_price_in_currency_units: unit_price,
          weight_in_store_units: weight,
          dimensions_in_store_units: dimensions
        )
      end

      private

      def normalize_quantity(value)
        quantity = value.is_a?(Integer) ? value : Integer(value.to_s, 10)
        raise InputError, "quantity must be greater than zero" unless quantity.positive?

        quantity
      rescue InputError
        raise
      rescue ArgumentError, TypeError
        raise InputError, "quantity must be a whole number"
      end

      def normalize_dimensions(values)
        dimensions = Array(values)
        raise InputError, "item dimensions must contain at most three values" if dimensions.length > 3

        dimensions.map do |value|
          dimension = Decimal.coerce(value || 0, name: "item dimension", error_class: InputError)
          raise InputError, "item dimensions must not be negative" if dimension.negative?

          dimension
        end.fill(BigDecimal("0"), dimensions.length...3).freeze
      end
    end

    CURRENCY_PATTERN = /\A[A-Z]{3}\z/

    attr_reader :items, :order_merchandise_total, :currency

    def initialize(items:, order_merchandise_total:, currency:)
      @items = Array(items).dup.freeze
      unless @items.all? { |item| item.is_a?(Item) }
        raise InputError, "package items must be SolidusWeightedShipping::PackageInput::Item values"
      end

      @order_merchandise_total = Decimal.coerce(
        order_merchandise_total,
        name: "order merchandise total",
        error_class: InputError
      )
      if @order_merchandise_total.negative?
        raise InputError, "order merchandise total must not be negative"
      end

      @currency = currency.to_s.strip.upcase.freeze
      raise InputError, "currency must be a three-letter code" unless CURRENCY_PATTERN.match?(@currency)

      freeze
    end

    def merchandise_total
      items.sum(BigDecimal("0")) do |item|
        item.unit_price_in_currency_units * item.quantity
      end
    end

    def total_weight(default_weight:)
      fallback = Decimal.coerce(default_weight, name: "default weight", error_class: InputError)
      raise InputError, "default weight must be greater than zero" unless fallback.positive?

      items.sum(BigDecimal("0")) do |item|
        weight = item.weight_in_store_units
        effective_weight = weight&.positive? ? weight : fallback
        effective_weight * Integer(item.quantity)
      end
    end

    def empty?
      items.empty?
    end
  end
end
