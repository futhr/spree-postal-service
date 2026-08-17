# frozen_string_literal: true

RSpec.describe SolidusWeightedShipping::Quote do
  it "builds immutable rated, free, unavailable, and empty results" do
    rated = described_class.rated(
      amount: "12.50",
      currency: " usd ",
      chargeable_weight_in_store_units: "3",
      parcel_count: 1,
      handling_fee: "2.50"
    )
    free = described_class.free_shipping(currency: "USD", chargeable_weight_in_store_units: "3")
    unavailable = described_class.unavailable(currency: "USD", reason: :maximum_item_weight_exceeded)
    empty = described_class.empty(currency: "USD")

    expect(rated.status).to eq(:rated)
    expect(rated.amount).to eq(decimal("12.50"))
    expect(rated.currency).to eq("USD")
    expect(rated).to be_available
    expect(rated).to be_frozen

    expect(free).to be_free_shipping
    expect(free.amount).to eq(decimal("0"))
    expect(free).to be_available

    expect(unavailable.status).to eq(:unavailable)
    expect(unavailable.amount).to be_nil
    expect(unavailable).not_to be_available

    expect(empty.status).to eq(:empty)
    expect(empty.amount).to eq(decimal("0"))

    same_rated = described_class.rated(
      amount: "12.50",
      currency: "USD",
      chargeable_weight_in_store_units: "3",
      parcel_count: 1,
      handling_fee: "2.50"
    )
    expect(same_rated).to eq(rated)
    expect(same_rated.hash).to eq(rated.hash)
  end

  it "rejects unknown or contradictory states" do
    common = {
      currency: "USD",
      chargeable_weight_in_store_units: "1",
      parcel_count: 1,
      handling_fee: "0"
    }

    expect { described_class.new(status: :mystery, amount: "1", **common) }
      .to raise_error(SolidusWeightedShipping::InputError, /unknown quote status/)
    expect { described_class.new(status: :rated, amount: "1", **common.merge(parcel_count: 0)) }
      .to raise_error(SolidusWeightedShipping::InputError, /at least one parcel/)
    expect do
      described_class.new(status: :unavailable, amount: nil, reason: nil, **common.merge(parcel_count: 0))
    end.to raise_error(SolidusWeightedShipping::InputError, /include a reason/)
    expect do
      described_class.new(status: :empty, amount: "1", **common.merge(parcel_count: 0))
    end.to raise_error(SolidusWeightedShipping::InputError, /must have zero/)
    expect { described_class.rated(amount: "1", currency: "US", chargeable_weight_in_store_units: "1", parcel_count: 1, handling_fee: "0") }
      .to raise_error(SolidusWeightedShipping::InputError, /three-letter/)
    expect { described_class.rated(amount: "1", currency: "USD", chargeable_weight_in_store_units: "1", parcel_count: "1.5", handling_fee: "0") }
      .to raise_error(SolidusWeightedShipping::InputError, /whole number/)
    expect { described_class.rated(amount: "-1", currency: "USD", chargeable_weight_in_store_units: "1", parcel_count: 1, handling_fee: "0") }
      .to raise_error(SolidusWeightedShipping::InputError, /quote amount must not be negative/)
    expect { described_class.rated(amount: "1", currency: "USD", chargeable_weight_in_store_units: "-1", parcel_count: 1, handling_fee: "0") }
      .to raise_error(SolidusWeightedShipping::InputError, /chargeable weight must not be negative/)
    expect { described_class.rated(amount: "1", currency: "USD", chargeable_weight_in_store_units: "1", parcel_count: -1, handling_fee: "0") }
      .to raise_error(SolidusWeightedShipping::InputError, /parcel count must not be negative/)
    expect { described_class.rated(amount: "1", currency: "USD", chargeable_weight_in_store_units: "1", parcel_count: 1, handling_fee: "-1") }
      .to raise_error(SolidusWeightedShipping::InputError, /handling fee must not be negative/)
    expect do
      described_class.new(status: :rated, amount: "1", reason: :unexpected, **common)
    end.to raise_error(SolidusWeightedShipping::InputError, /must not include an unavailable reason/)
    expect do
      described_class.new(status: :unavailable, amount: "1", reason: :oversized, **common.merge(parcel_count: 0))
    end.to raise_error(SolidusWeightedShipping::InputError, /must not include an amount/)
  end
end
