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

  it "exposes the explicit quote used by compute_package" do
    quote = calculator.quote_package(package)

    expect(quote).to be_a(SolidusWeightedShipping::Quote)
    expect(quote.amount).to eq(calculator.compute_package(package))
    expect(quote.currency).to eq("USD")
  end

  it "uses package contents for parcel constraints" do
    allow(variant).to receive(:weight).and_return(BigDecimal("20"))

    expect(calculator.available?(package)).to be(false)
    expect(calculator.compute_package(package)).to be_nil
  end

  it "returns unavailable for invalid configuration instead of crashing rate selection" do
    calculator.preferred_rate_table = "2: 9\n1: 6"

    expect(calculator.available?(package)).to be(false)
    expect(calculator.compute_package(package)).to be_nil
  end

  it "surfaces invalid configuration through calculator validation" do
    calculator.preferred_rate_table = "2: 9\n1: 6"

    expect(calculator).not_to be_valid
    expect(calculator.errors[:base]).not_to be_empty
  end

  it "exposes only canonical weighted-shipping preferences to the admin" do
    expect(calculator.admin_form_preference_names).to eq(
      %i[
        rate_table
        maximum_item_weight
        maximum_item_width
        maximum_item_length
        free_shipping_threshold
        handling_threshold
        handling_fee
        default_item_weight
      ]
    )
    expect(calculator.preference_type(:rate_table)).to eq(:text)
    expect(calculator.admin_form_preference_names).not_to include(:weight_table, :price_table, :max_price)
  end

  it "uses persisted legacy preferences until they are migrated" do
    calculator.preferences[:weight_table] = "1 2"
    calculator.preferences[:price_table] = "5 8"
    calculator.preferences[:max_price] = BigDecimal("1000")

    expect(calculator).to be_legacy_preferences
    expect(calculator.compute_package(package)).to eq(BigDecimal("40"))

    expect(calculator.migrate_legacy_preferences!).to be(true)
    expect(calculator).not_to be_legacy_preferences
    expect(calculator.preferred_rate_table).to eq("1: 5\n2: 8")
    expect(calculator.preferred_free_shipping_threshold).to eq(BigDecimal("1000"))
    expect(calculator.compute_package(package)).to eq(BigDecimal("40"))
    expect(calculator.migrate_legacy_preferences!).to be(false)
  end

  it "makes canonical admin edits supersede their legacy keys" do
    calculator.preferences[:weight_table] = "1 2"
    calculator.preferences[:price_table] = "5 8"

    calculator.preferred_rate_table = "10: 3\n20: 5"

    expect(calculator.preferences).not_to include(:weight_table, :price_table)
    expect(calculator.compute_package(package)).to eq(BigDecimal("3"))
  end

  it "restores legacy preferences when migration validation fails" do
    calculator.preferences[:weight_table] = "2 1"
    calculator.preferences[:price_table] = "5 8"
    before = calculator.preferences.dup

    expect { calculator.migrate_legacy_preferences! }
      .to raise_error(SolidusWeightedShipping::ConfigurationError)
    expect(calculator.preferences).to eq(before)
  end

  it "invalidates the cached policy when configuration changes" do
    expect(calculator.compute_package(package)).to eq(BigDecimal("15"))

    calculator.preferred_rate_table = "10: 2\n20: 4"

    expect(calculator.compute_package(package)).to eq(BigDecimal("2"))
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
