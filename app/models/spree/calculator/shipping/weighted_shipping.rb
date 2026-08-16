# frozen_string_literal: true

module Spree
  module Calculator::Shipping
    class WeightedShipping < ShippingCalculator
      preference :weight_table, :string, default: "1 2 5 10 20"
      preference :price_table, :string, default: "6 9 12 15 18"
      preference :max_item_weight, :decimal, default: 18
      preference :max_item_width, :decimal, default: 60
      preference :max_item_length, :decimal, default: 120
      preference :max_price, :decimal, default: 120
      preference :handling_max, :decimal, default: 50
      preference :handling_fee, :decimal, default: 10
      preference :default_weight, :decimal, default: 1

      validate :weighted_shipping_configuration

      def self.description
        Spree.t(:weighted_shipping)
      end

      def available?(package)
        policy.available?(package_input(package))
      rescue SolidusWeightedShipping::ConfigurationError, SolidusWeightedShipping::InputError
        false
      end

      def compute_package(package)
        quote = policy.quote(package_input(package))
        quote.amount if quote.available?
      end

      private

      def policy
        SolidusWeightedShipping::Calculator.new(
          rate_table: SolidusWeightedShipping::RateTable.from_legacy(
            thresholds: preferred_weight_table,
            prices: preferred_price_table
          ),
          constraints: SolidusWeightedShipping::Constraints.new(
            max_item_weight_in_store_units: preferred_max_item_weight,
            max_item_width_in_store_units: preferred_max_item_width,
            max_item_length_in_store_units: preferred_max_item_length,
            default_weight_in_store_units: preferred_default_weight
          ),
          free_shipping_threshold_in_currency_units: preferred_max_price,
          handling_threshold_in_currency_units: preferred_handling_max,
          handling_fee_in_currency_units: preferred_handling_fee
        )
      end

      def package_input(package)
        items = package.contents.map do |content_item|
          variant = content_item.variant
          SolidusWeightedShipping::PackageInput::Item.new(
            quantity: content_item.quantity,
            unit_price_in_currency_units: content_item.price,
            weight_in_store_units: variant.weight,
            dimensions_in_store_units: [variant.width, variant.depth, variant.height]
          )
        end

        order_total = package.order&.item_total || items.sum(BigDecimal("0")) do |item|
          item.unit_price_in_currency_units * item.quantity
        end

        SolidusWeightedShipping::PackageInput.new(
          items: items,
          order_merchandise_total: order_total,
          currency: package.currency
        )
      end

      def weighted_shipping_configuration
        policy
      rescue SolidusWeightedShipping::ConfigurationError => error
        errors.add(:base, error.message)
      end
    end
  end
end
