# frozen_string_literal: true

RSpec.describe SolidusWeightedShipping::Constraints do
  subject(:constraints) do
    described_class.new(
      max_item_weight_in_store_units: "18",
      max_item_width_in_store_units: "60",
      max_item_length_in_store_units: "120",
      default_weight_in_store_units: "1"
    )
  end

  it "accepts exact boundaries" do
    item = weighted_item(weight: "18", dimensions: %w[120 60 60])

    expect(constraints.eligibility_for(item)).to be_eligible
  end

  it "returns precise ineligibility reasons" do
    expectations = {
      weighted_item(weight: "18.0001") => :maximum_item_weight_exceeded,
      weighted_item(dimensions: %w[120.0001 1 1]) => :maximum_item_length_exceeded,
      weighted_item(dimensions: %w[100 60.0001 1]) => :maximum_item_width_exceeded
    }

    expectations.each do |item, reason|
      eligibility = constraints.eligibility_for(item)
      expect(eligibility).not_to be_eligible
      expect(eligibility.reason).to eq(reason)
    end
  end

  it "is independent of dimension orientation" do
    allowed = %w[100 60 30]
    rejected = %w[100 61 30]

    allowed.permutation.each do |dimensions|
      expect(constraints.item_allowed?(weighted_item(dimensions:))).to be(true)
    end
    rejected.permutation.each do |dimensions|
      eligibility = constraints.eligibility_for(weighted_item(dimensions:))
      expect(eligibility.reason).to eq(:maximum_item_width_exceeded)
    end
  end

  it "applies the default weight to nil, zero, and negative historical values" do
    [nil, "0", "-1"].each do |weight|
      item = weighted_item(weight:)
      expect(constraints.effective_weight_for(item)).to eq(decimal("1"))
      expect(constraints.item_allowed?(item)).to be(true)
    end
  end

  it "stops at the first ineligible package item" do
    package = weighted_package(
      items: [
        weighted_item(weight: "19"),
        weighted_item(dimensions: %w[121 1 1])
      ]
    )

    expect(constraints.package_eligibility(package).reason).to eq(:maximum_item_weight_exceeded)
  end

  it "rejects invalid configuration and input types" do
    %i[
      max_item_weight_in_store_units
      max_item_width_in_store_units
      max_item_length_in_store_units
      default_weight_in_store_units
    ].each do |name|
      attributes = {
        max_item_weight_in_store_units: "18",
        max_item_width_in_store_units: "60",
        max_item_length_in_store_units: "120",
        default_weight_in_store_units: "1"
      }
      attributes[name] = "0"

      expect { described_class.new(**attributes) }
        .to raise_error(SolidusWeightedShipping::ConfigurationError, /greater than zero/)
    end

    expect { constraints.eligibility_for(Object.new) }
      .to raise_error(SolidusWeightedShipping::InputError, /PackageInput::Item/)
    expect { constraints.package_eligibility(Object.new) }
      .to raise_error(SolidusWeightedShipping::InputError, /PackageInput/)
  end
end
