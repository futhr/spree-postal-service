# frozen_string_literal: true

require_dependency "spree/calculator"
require_dependency "spree/shipping_calculator"

module Spree
  module Calculator::Shipping
    class PostalService < ShippingCalculator
      preference :weight_table, :string, default: "1 2 5 10 20"
      preference :price_table, :string, default: "6 9 12 15 18"
      preference :max_item_weight, :decimal, default: 18
      preference :max_item_width, :decimal, default: 60
      preference :max_item_length, :decimal, default: 120
      preference :max_price, :decimal, default: 120
      preference :handling_max, :decimal, default: 50
      preference :handling_fee, :decimal, default: 10
      preference :default_weight, :decimal, default: 1

      validate :postal_service_configuration

      def self.description
        Spree.t(:postal_service)
      end

      def available?(package)
        policy.available?(package_input(package))
      rescue SpreePostalService::ConfigurationError
        false
      end

      def compute_package(package)
        policy.quote(package_input(package))
      end

      private

      def policy
        SpreePostalService::Calculator.new(
          rate_table: SpreePostalService::RateTable.new(
            thresholds: preferred_weight_table,
            prices: preferred_price_table
          ),
          constraints: SpreePostalService::Constraints.new(
            max_item_weight: preferred_max_item_weight,
            max_item_width: preferred_max_item_width,
            max_item_length: preferred_max_item_length,
            default_weight: preferred_default_weight
          ),
          free_shipping_threshold: preferred_max_price,
          handling_threshold: preferred_handling_max,
          handling_fee: preferred_handling_fee
        )
      end

      def package_input(package)
        items = package.contents.map do |content_item|
          variant = content_item.variant
          SpreePostalService::PackageInput::Item.new(
            quantity: content_item.quantity,
            unit_price: content_item.price,
            weight: variant.weight,
            dimensions: [variant.width, variant.depth, variant.height]
          )
        end

        order_total = package.order&.item_total || items.sum(BigDecimal("0")) { |item| item.unit_price * item.quantity }

        SpreePostalService::PackageInput.new(
          items: items,
          order_merchandise_total: order_total
        )
      end

      def postal_service_configuration
        policy
      rescue SpreePostalService::ConfigurationError => error
        errors.add(:base, error.message)
      end
    end
  end
end
