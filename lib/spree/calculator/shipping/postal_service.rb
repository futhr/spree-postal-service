module Spree
  class Calculator
    module Shipping
      class PostalService < Spree::ShippingCalculator

        preference :weight_table,    :string,  default: '1 2 5 10 20'
        preference :price_table,     :string,  default: '6 9 12 15 18'
        preference :max_item_weight, :decimal, default: 18
        preference :max_item_width,  :decimal, default: 60
        preference :max_item_length, :decimal, default: 120
        preference :max_price,       :decimal, default: 120
        preference :handling_max,    :decimal, default: 50
        preference :handling_fee,    :decimal, default: 10
        preference :default_weight,  :decimal, default: 1

        class << self
          def description
            Spree.t(:postal_service)
          end

          def register
            super
          end
        end

        attr_accessor :line_items

        def item_oversized?(variant)
          sizes = [
            variant.width ? variant.width : 0,
            variant.depth ? variant.depth : 0,
            variant.height ? variant.height : 0
          ].sort.reverse

          return true if sizes[0] > preferred_max_item_length # Longest side.
          return true if sizes[1] > preferred_max_item_width  # Second longest side.
          false
        end

        # Determine if weight or size goes over bounds.
        def available?(package)
          package.order.variants.each do |variant|
            return false if item_within_bounds?(variant.weight) # 18
            return false if item_oversized?(variant)
          end
          true
        end

        # As order_or_line_items we always get line items, as calculable we have
        # Coupon, ShippingMethod or ShippingRate.
        def compute(package)
          @line_items ||= package.order.line_items
          total_price  = compute_total_price
          total_weight = compute_total_weight
          shipping     = 0

          return 0.0 if total_price > preferred_max_price

          while total_weight > weights.last # In several packages if need be.
            total_weight -= weights.last
            shipping += prices.last
          end

          [shipping, prices[compute_index(total_weight)], handling_fee(total_price)].compact.sum
        end

        private

        def compute_total_weight
          line_items.map do |item|
            weight = item.variant.weight > 0 ? item.variant.weight : preferred_default_weight
            item.quantity * weight
          end.reduce(:+)
        end

        def compute_total_price
          line_items.map { |item| item.price * item.quantity }.reduce(:+)
        end

        def compute_index(total_weight)
          index = weights.length - 2
          while index >= 0
            break if total_weight > weights[index]
            index -= 1
          end
          index + 1
        end

        def item_within_bounds?(weight)
          weight && weight > preferred_max_item_weight
        end

        def handling_fee(total_price)
          preferred_handling_max < total_price ? 0 : preferred_handling_fee
        end

        def prices
          @prices ||= preferred_price_table.split.map(&:to_f)
        end

        def weights
          @weights ||= preferred_weight_table.split.map(&:to_f)
        end
      end
    end
  end
end
