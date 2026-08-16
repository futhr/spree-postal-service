# frozen_string_literal: true

RSpec.describe SpreePostalService::Calculator do
  subject(:calculator) do
    described_class.new(
      rate_table: SpreePostalService::RateTable.new(thresholds: "1 2 5 10 20", prices: "6 9 12 15 18"),
      constraints: SpreePostalService::Constraints.new(
        max_item_weight: 18,
        max_item_width: 60,
        max_item_length: 120,
        default_weight: 1
      ),
      free_shipping_threshold: 120,
      handling_threshold: 50,
      handling_fee: 10
    )
  end

  def package(weight:, unit_price:, quantity: 1, dimensions: [0, 0, 0], order_total: nil)
    item = SpreePostalService::PackageInput::Item.new(
      quantity: quantity,
      unit_price: BigDecimal(unit_price.to_s),
      weight: weight.nil? ? nil : BigDecimal(weight.to_s),
      dimensions: dimensions
    )

    SpreePostalService::PackageInput.new(
      items: [item],
      order_merchandise_total: order_total || (unit_price * quantity)
    )
  end

  it "preserves legacy rate and handling behavior" do
    expect(calculator.quote(package(weight: 10, unit_price: 100))).to eq(BigDecimal("15"))
    expect(calculator.quote(package(weight: 10, unit_price: 40))).to eq(BigDecimal("25"))
    expect(calculator.quote(package(weight: 0.5, unit_price: 40))).to eq(BigDecimal("16"))
  end

  it "uses the configured fallback weight when weight is missing" do
    expect(calculator.quote(package(weight: nil, unit_price: 100, quantity: 3, order_total: 100))).to eq(BigDecimal("12"))
  end

  it "keeps the historical strict free-shipping boundary" do
    expect(calculator.quote(package(weight: 1, unit_price: 120, order_total: 120))).to eq(BigDecimal("6"))
    expect(calculator.quote(package(weight: 1, unit_price: 121, order_total: 121))).to eq(BigDecimal("0"))
  end

  it "rejects overweight and oversized items independent of orientation" do
    expect(calculator.available?(package(weight: 20, unit_price: 10))).to be(false)
    expect(calculator.available?(package(weight: 10, unit_price: 10, dimensions: [30, 40, 130]))).to be(false)
    expect(calculator.available?(package(weight: 10, unit_price: 10, dimensions: [30, 70, 80]))).to be(false)
    expect(calculator.available?(package(weight: 10, unit_price: 10, dimensions: [80, 30, 70]))).to be(false)
  end
end
