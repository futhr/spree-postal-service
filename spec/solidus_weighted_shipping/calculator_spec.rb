# frozen_string_literal: true

RSpec.describe SolidusWeightedShipping::Calculator do
  subject(:calculator) { weighted_calculator }

  it "preserves weighted rate and handling behavior" do
    expect(calculator.quote(weighted_package(weight: "10", unit_price: "100")).amount).to eq(decimal("15"))
    expect(calculator.quote(weighted_package(weight: "10", unit_price: "40")).amount).to eq(decimal("25"))
    expect(calculator.quote(weighted_package(weight: "0.5", unit_price: "40")).amount).to eq(decimal("16"))
  end

  it "weights mixed variants and quantities inside the quoted package" do
    package = weighted_package(
      items: [
        weighted_item(quantity: 2, unit_price: "30", weight: "2"),
        weighted_item(quantity: 3, unit_price: "20", weight: nil)
      ],
      order_total: "120"
    )

    quote = calculator.quote(package)
    expect(quote.status).to eq(:rated)
    expect(quote.chargeable_weight_in_store_units).to eq(decimal("7"))
    expect(quote.amount).to eq(decimal("15"))
  end

  it "keeps the historical strict free-shipping boundary at order scope" do
    boundary = weighted_package(weight: "1", unit_price: "120", order_total: "120")
    above = weighted_package(weight: "1", unit_price: "10", order_total: "120.0001")

    expect(calculator.quote(boundary).status).to eq(:rated)
    expect(calculator.quote(boundary).amount).to eq(decimal("6"))
    expect(calculator.quote(above).status).to eq(:free_shipping)
    expect(calculator.quote(above).amount).to eq(decimal("0"))
  end

  it "applies handling per package at an inclusive package-total boundary" do
    at_boundary = weighted_package(unit_price: "50", order_total: "100")
    above_boundary = weighted_package(unit_price: "50.0001", order_total: "100")

    expect(calculator.quote(at_boundary).handling_fee).to eq(decimal("10"))
    expect(calculator.quote(at_boundary).amount).to eq(decimal("16"))
    expect(calculator.quote(above_boundary).handling_fee).to eq(decimal("0"))
    expect(calculator.quote(above_boundary).amount).to eq(decimal("6"))
  end

  it "checks parcel eligibility before granting free shipping" do
    package = weighted_package(weight: "19", unit_price: "200", order_total: "200")

    quote = calculator.quote(package)
    expect(quote.status).to eq(:unavailable)
    expect(quote.reason).to eq(:maximum_item_weight_exceeded)
    expect(quote.amount).to be_nil
    expect(calculator.available?(package)).to be(false)
  end

  it "returns an explicit zero quote for an empty package" do
    quote = calculator.quote(weighted_package(items: [], order_total: "0"))

    expect(quote.status).to eq(:empty)
    expect(quote.amount).to eq(decimal("0"))
    expect(quote.parcel_count).to eq(0)
    expect(quote.handling_fee).to eq(decimal("0"))
  end

  it "rejects invalid collaborator and package types" do
    expect { calculator.quote(Object.new) }
      .to raise_error(SolidusWeightedShipping::InputError, /PackageInput/)
    expect do
      described_class.new(
        rate_table: Object.new,
        constraints: Object.new,
        free_shipping_threshold_in_currency_units: "1",
        handling_threshold_in_currency_units: "1",
        handling_fee_in_currency_units: "1"
      )
    end.to raise_error(SolidusWeightedShipping::ConfigurationError, /RateTable/)

    expect do
      described_class.new(
        rate_table: SolidusWeightedShipping::RateTable.parse("1: 1"),
        constraints: Object.new,
        free_shipping_threshold_in_currency_units: "1",
        handling_threshold_in_currency_units: "1",
        handling_fee_in_currency_units: "1"
      )
    end.to raise_error(SolidusWeightedShipping::ConfigurationError, /Constraints/)
  end

  it "accepts specialized package input values" do
    specialized_package_class = Class.new(SolidusWeightedShipping::PackageInput)
    package = specialized_package_class.new(
      items: [weighted_item],
      order_merchandise_total: "100",
      currency: "USD"
    )

    expect(calculator.quote(package)).to be_available
  end

  it "rejects negative or inexact threshold configuration" do
    expect { weighted_calculator(handling_fee: "-1") }
      .to raise_error(SolidusWeightedShipping::ConfigurationError, /must not be negative/)
    expect { weighted_calculator(free_shipping_threshold: 120.0) }
      .to raise_error(SolidusWeightedShipping::ConfigurationError, /exact decimal/)
  end

  it "produces nonnegative quotes for deterministic generated packages" do
    random = Random.new(54_321)

    500.times do
      weight = decimal(random.rand(1..1_800).to_s) / 100
      price = decimal(random.rand(0..12_000).to_s) / 100
      package = weighted_package(weight:, unit_price: price, order_total: price)
      quote = calculator.quote(package)

      expect(quote).to be_available
      expect(quote.amount).to be >= decimal("0")
      expect(quote.chargeable_weight_in_store_units).to eq(weight)
    end
  end

  it "is monotonic for a monotonic table when thresholds do not change" do
    monotonic = weighted_calculator(
      rate_table: "1: 2\n2: 4\n5: 8\n10: 12\n20: 20",
      handling_threshold: "0",
      handling_fee: "0",
      free_shipping_threshold: "1000000",
      max_item_weight: "100"
    )
    amounts = (1..6_000).map do |hundredths|
      monotonic.quote(weighted_package(weight: decimal(hundredths.to_s) / 100)).amount
    end

    expect(amounts.each_cons(2)).to all(satisfy { |left, right| left <= right })
  end
end
