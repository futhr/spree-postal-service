# frozen_string_literal: true

module DomainSpecHelpers
  def decimal(value)
    BigDecimal(value.to_s)
  end

  def weighted_item(
    quantity: 1,
    unit_price: "100",
    weight: "1",
    dimensions: ["0", "0", "0"]
  )
    SolidusWeightedShipping::PackageInput::Item.new(
      quantity:,
      unit_price_in_currency_units: unit_price,
      weight_in_store_units: weight,
      dimensions_in_store_units: dimensions
    )
  end

  def weighted_package(
    items: nil,
    quantity: 1,
    unit_price: "100",
    weight: "1",
    dimensions: ["0", "0", "0"],
    order_total: nil,
    currency: "USD"
  )
    package_items = items || [
      weighted_item(quantity:, unit_price:, weight:, dimensions:)
    ]
    total = order_total || package_items.sum(decimal("0")) do |item|
      item.unit_price_in_currency_units * item.quantity
    end

    SolidusWeightedShipping::PackageInput.new(
      items: package_items,
      order_merchandise_total: total,
      currency:
    )
  end

  def weighted_calculator(
    rate_table: "1: 6\n2: 9\n5: 12\n10: 15\n20: 18",
    max_item_weight: "18",
    max_item_width: "60",
    max_item_length: "120",
    default_weight: "1",
    free_shipping_threshold: "120",
    handling_threshold: "50",
    handling_fee: "10"
  )
    SolidusWeightedShipping::Calculator.new(
      rate_table: SolidusWeightedShipping::RateTable.parse(rate_table),
      constraints: SolidusWeightedShipping::Constraints.new(
        max_item_weight_in_store_units: max_item_weight,
        max_item_width_in_store_units: max_item_width,
        max_item_length_in_store_units: max_item_length,
        default_weight_in_store_units: default_weight
      ),
      free_shipping_threshold_in_currency_units: free_shipping_threshold,
      handling_threshold_in_currency_units: handling_threshold,
      handling_fee_in_currency_units: handling_fee
    )
  end
end
