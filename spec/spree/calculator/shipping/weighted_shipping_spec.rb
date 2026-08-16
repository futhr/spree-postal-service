# frozen_string_literal: true

require "rails_helper"
require "spree_postal_service"

RSpec.describe Spree::Calculator::Shipping::WeightedShipping do
  subject(:calculator) { described_class.new }

  let(:variant) do
    instance_double(
      Spree::Variant,
      weight: BigDecimal("10"),
      width: BigDecimal("30"),
      depth: BigDecimal("30"),
      height: BigDecimal("30")
    )
  end

  let(:content_item) do
    instance_double(
      Spree::Stock::ContentItem,
      variant:,
      quantity: 1,
      price: BigDecimal("100")
    )
  end

  let(:order) { instance_double(Spree::Order, item_total: BigDecimal("100")) }
  let(:package) do
    instance_double(
      Spree::Stock::Package,
      contents: [content_item],
      order:,
      currency: "USD"
    )
  end

  it "uses the current Solidus compute_package API" do
    expect(calculator.compute_package(package)).to eq(BigDecimal("15"))
  end

  it "uses package contents for parcel constraints" do
    allow(variant).to receive(:weight).and_return(BigDecimal("20"))

    expect(calculator.available?(package)).to be(false)
    expect(calculator.compute_package(package)).to be_nil
  end

  it "returns unavailable for invalid configuration instead of crashing rate selection" do
    calculator.preferred_weight_table = "2 1"

    expect(calculator.available?(package)).to be(false)
  end

  it "surfaces invalid configuration through calculator validation" do
    calculator.preferred_weight_table = "2 1"

    expect(calculator).not_to be_valid
    expect(calculator.errors[:base]).not_to be_empty
  end

  it "registers only the canonical calculator for new shipping methods" do
    expect(Rails.application.config.spree.calculators.shipping_methods)
      .to include(Spree::Calculator::Shipping::WeightedShipping)
    expect(Rails.application.config.spree.calculators.shipping_methods)
      .not_to include(Spree::Calculator::Shipping::PostalService)
  end

  it "keeps the original calculator class as a migration shim" do
    expect(Spree::Calculator::Shipping::PostalService).to be < described_class
    expect(SpreePostalService).to equal(SolidusWeightedShipping)
  end
end
