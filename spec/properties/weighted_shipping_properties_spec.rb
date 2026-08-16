# frozen_string_literal: true

ENV["RANTLY_VERBOSE"] ||= "0"
require "rantly/rspec_extensions"

RSpec.describe "weighted shipping properties" do
  let(:table) do
    SolidusWeightedShipping::RateTable.parse("1: 6\n2: 9\n5: 12\n10: 15\n20: 18")
  end

  it "conserves weight when decomposing any generated multi-parcel rate" do
    property_of { range(0, 1_000_000) }.check(300) do |hundredths|
      weight = decimal(hundredths.to_s) / 100
      rate = table.rate_for(weight)
      reconstructed = (table.max_weight * rate.full_parcel_count) + rate.remainder_weight_in_store_units

      expect(reconstructed).to eq(weight)
      expect(rate.remainder_weight_in_store_units).to be >= decimal("0")
      expect(rate.remainder_weight_in_store_units).to be < table.max_weight unless rate.remainder_weight_in_store_units.zero?
    end
  end

  it "never decreases a monotonic rate table as generated weight increases" do
    property_of do
      threshold_steps = array(5) { range(1, 2_000) }
      price_steps = array(5) { range(0, 2_000) }
      weights = [range(0, 100_000), range(0, 100_000)].sort
      [threshold_steps, price_steps, weights]
    end.check(300) do |threshold_steps, price_steps, weights|
      thresholds = threshold_steps.each_with_object([]) do |step, values|
        values << step + values.fetch(-1, 0)
      end
      prices = price_steps.each_with_object([]) do |step, values|
        values << step + values.fetch(-1, 0)
      end
      generated_table = SolidusWeightedShipping::RateTable.new(
        bands: thresholds.zip(prices)
      )
      lighter, heavier = weights.map { |value| decimal(value.to_s) / 100 }

      expect(generated_table.rate_for(lighter).amount)
        .to be <= generated_table.rate_for(heavier).amount
    end
  end

  it "makes eligibility independent of every generated dimension orientation" do
    constraints = SolidusWeightedShipping::Constraints.new(
      max_item_weight_in_store_units: "18",
      max_item_width_in_store_units: "60",
      max_item_length_in_store_units: "120",
      default_weight_in_store_units: "1"
    )

    property_of { array(3) { range(0, 20_000) } }.check(300) do |hundredths|
      dimensions = hundredths.map { |value| decimal(value.to_s) / 100 }
      reasons = dimensions.permutation.map do |orientation|
        constraints.eligibility_for(weighted_item(dimensions: orientation)).reason
      end

      expect(reasons.uniq.length).to eq(1)
    end
  end

  it "produces available nonnegative quotes for every generated valid package" do
    calculator = weighted_calculator

    property_of do
      [
        range(1, 1_800),
        range(0, 12_000),
        range(1, 5),
        array(3) { range(0, 6_000) }
      ]
    end.check(300) do |weight_hundredths, price_hundredths, quantity, dimension_hundredths|
      weight = decimal(weight_hundredths.to_s) / 100
      price = decimal(price_hundredths.to_s) / 100
      dimensions = dimension_hundredths.map { |value| decimal(value.to_s) / 100 }
      package = weighted_package(
        quantity:,
        weight:,
        unit_price: price,
        dimensions:,
        order_total: price * quantity
      )

      quote = calculator.quote(package)
      expect(quote).to be_available
      expect(quote.amount).to be >= decimal("0")
      expect(quote.currency).to eq("USD")
    end
  end
end
