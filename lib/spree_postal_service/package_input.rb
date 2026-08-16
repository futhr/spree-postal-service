# frozen_string_literal: true

module SpreePostalService
  class PackageInput
    Item = Data.define(:quantity, :unit_price, :weight, :dimensions)

    attr_reader :items, :order_merchandise_total

    def initialize(items:, order_merchandise_total:)
      @items = items.freeze
      @order_merchandise_total = Decimal.coerce(order_merchandise_total, name: "order merchandise total")
      freeze
    end

    def merchandise_total
      items.sum(BigDecimal("0")) do |item|
        Decimal.coerce(item.unit_price, name: "unit price") * Integer(item.quantity)
      end
    end

    def total_weight(default_weight:)
      fallback = Decimal.coerce(default_weight, name: "default weight")

      items.sum(BigDecimal("0")) do |item|
        weight = Decimal.coerce(item.weight || 0, name: "item weight")
        effective_weight = weight.positive? ? weight : fallback
        effective_weight * Integer(item.quantity)
      end
    end
  end
end
