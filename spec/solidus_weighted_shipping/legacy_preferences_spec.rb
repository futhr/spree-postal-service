# frozen_string_literal: true

RSpec.describe SolidusWeightedShipping::LegacyPreferences do
  describe ".migrate" do
    it "atomically converts every renamed preference" do
      source = {
        rate_table: "default already merged by Solidus",
        weight_table: "1 2 5",
        price_table: "6 9 12",
        max_item_weight: decimal("18"),
        max_item_width: decimal("60"),
        max_item_length: decimal("120"),
        max_price: decimal("120"),
        handling_max: decimal("50"),
        handling_fee: decimal("10"),
        default_weight: decimal("1"),
        currency: "EUR"
      }
      original = source.dup

      migration = described_class.migrate(source)

      expect(migration).to be_changed
      expect(migration.preferences).to include(
        rate_table: "1: 6\n2: 9\n5: 12",
        maximum_item_weight: decimal("18"),
        maximum_item_width: decimal("60"),
        maximum_item_length: decimal("120"),
        free_shipping_threshold: decimal("120"),
        handling_threshold: decimal("50"),
        handling_fee: decimal("10"),
        default_item_weight: decimal("1"),
        currency: "EUR"
      )
      expect(migration.preferences.keys & described_class::LEGACY_KEYS).to be_empty
      expect(source).to eq(original)
    end

    it "accepts string keys emitted by historical serializers" do
      migration = described_class.migrate(
        "weight_table" => "1 2",
        "price_table" => "3 4",
        "max_price" => "99"
      )

      expect(migration.preferences[:rate_table]).to eq("1: 3\n2: 4")
      expect(migration.preferences[:free_shipping_threshold]).to eq("99")
      expect(migration.preferences).not_to include("weight_table", "price_table", "max_price")
    end

    it "returns an unchanged copy for canonical preferences" do
      source = {rate_table: "1: 2", handling_fee: decimal("1")}
      migration = described_class.migrate(source)

      expect(migration).not_to be_changed
      expect(migration.preferences).to eq(source)
      expect(migration.preferences).not_to equal(source)
      expect(described_class.legacy?(source)).to be(false)
    end

    it "rejects incomplete or invalid historical tables without mutating input" do
      source = {weight_table: "2 1", price_table: "3 4"}
      original = source.dup

      expect { described_class.migrate(source) }
        .to raise_error(SolidusWeightedShipping::ConfigurationError, /strictly increasing/)
      expect(source).to eq(original)
    end
  end

  describe ".legacy?" do
    it "detects symbol and string legacy keys" do
      expect(described_class.legacy?(max_price: "100")).to be(true)
      expect(described_class.legacy?("default_weight" => "1")).to be(true)
    end
  end
end
