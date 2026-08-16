# frozen_string_literal: true

RSpec.describe SolidusWeightedShipping::RateTable do
  subject(:table) { described_class.parse(source) }

  let(:source) { "1: 6\n2: 9\n5: 12\n10: 15\n20: 18" }

  describe ".parse" do
    it "builds a canonical immutable table" do
      expect(table.dump).to eq(source)
      expect(table.bands.map(&:maximum_weight_in_store_units)).to eq(
        %w[1 2 5 10 20].map { |value| decimal(value) }
      )
      expect(table).to be_frozen
      expect(table.bands).to be_frozen
      expect(table.bands).to all(be_frozen)
    end

    it "normalizes insignificant whitespace and blank lines" do
      equivalent = described_class.parse("\n  1 : 6 \n\t2:9\n 5:  12\n10 :15\n20:18\n")

      expect(equivalent.dump).to eq(source)
      expect(equivalent.bands).to eq(table.bands)
    end

    it "rejects malformed public configuration" do
      invalid_values = [
        nil,
        "",
        "1 6",
        "1: 6: 7",
        "one: 6",
        "1: nope",
        "NaN: 1",
        "1: Infinity"
      ]

      invalid_values.each do |value|
        expect { described_class.parse(value) }
          .to raise_error(SolidusWeightedShipping::ConfigurationError)
      end
    end
  end

  describe ".from_legacy" do
    it "converts historical parallel whitespace preferences deterministically" do
      legacy = described_class.from_legacy(
        thresholds: " 1\t2  5\n10 20 ",
        prices: "6 9\t12 15\n18"
      )

      expect(legacy.dump).to eq(source)
      expect(legacy.bands).to eq(table.bands)
    end

    it "rejects empty, uneven, and invalid legacy tables" do
      invalid_pairs = [
        ["", ""],
        ["1 2", "6"],
        ["1 1", "6 9"],
        ["2 1", "6 9"],
        ["0 1", "6 9"],
        ["1 2", "6 -1"]
      ]

      invalid_pairs.each do |thresholds, prices|
        expect { described_class.from_legacy(thresholds:, prices:) }
          .to raise_error(SolidusWeightedShipping::ConfigurationError)
      end
    end
  end

  describe "validation" do
    it "rejects malformed structured bands and binary floats" do
      expect { described_class.new(bands: [["1"]]) }
        .to raise_error(SolidusWeightedShipping::ConfigurationError, /maximum weight and price/)
      expect { described_class.new(bands: [[1.0, "6"]]) }
        .to raise_error(SolidusWeightedShipping::ConfigurationError, /exact decimal/)
    end

    it "bounds the number of configured bands" do
      bands = Array.new(described_class::MAX_BANDS + 1) { |index| [index + 1, "1"] }

      expect { described_class.new(bands:) }
        .to raise_error(SolidusWeightedShipping::ConfigurationError, /more than 1000/)
    end
  end

  describe "rating" do
    it "preserves threshold and repeated-maximum parcel behavior" do
      expected = {
        "0" => ["0", 0, "0"],
        "0.0001" => ["6", 1, "0.0001"],
        "1" => ["6", 1, "1"],
        "1.0001" => ["9", 1, "1.0001"],
        "2" => ["9", 1, "2"],
        "2.0001" => ["12", 1, "2.0001"],
        "5" => ["12", 1, "5"],
        "5.0001" => ["15", 1, "5.0001"],
        "10" => ["15", 1, "10"],
        "10.0001" => ["18", 1, "10.0001"],
        "20" => ["18", 1, "0"],
        "20.0001" => ["24", 2, "0.0001"],
        "25" => ["30", 2, "5"],
        "40" => ["36", 2, "0"],
        "41" => ["42", 3, "1"],
        "60" => ["54", 3, "0"]
      }

      expected.each do |weight, (amount, parcel_count, remainder)|
        rate = table.rate_for(weight)
        expect(rate.amount).to eq(decimal(amount)), "amount for weight #{weight}"
        expect(rate.parcel_count).to eq(parcel_count), "parcel count for weight #{weight}"
        expect(rate.remainder_weight_in_store_units).to eq(decimal(remainder)), "remainder for weight #{weight}"
      end
    end

    it "rejects invalid input weights" do
      [-1, 1.0, "NaN", "Infinity", nil].each do |weight|
        expect { table.rate_for(weight) }.to raise_error(SolidusWeightedShipping::InputError)
      end

      expect { table.price_for("0") }
        .to raise_error(SolidusWeightedShipping::InputError, /greater than zero/)
      expect { table.price_for("21") }
        .to raise_error(SolidusWeightedShipping::InputError, /exceeds/)
    end

    it "conserves chargeable weight across parcel decomposition" do
      random = Random.new(12_345)

      500.times do
        weight = decimal(random.rand(0..100_000).to_s) / 100
        rate = table.rate_for(weight)
        reconstructed = (table.max_weight * rate.full_parcel_count) + rate.remainder_weight_in_store_units

        expect(reconstructed).to eq(weight)
        expect(rate.amount).to be >= decimal("0")
      end
    end
  end
end
