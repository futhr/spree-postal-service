# frozen_string_literal: true

RSpec.describe SolidusWeightedShipping::Decimal do
  describe ".coerce" do
    it "accepts exact decimal representations" do
      value = BigDecimal("1.25")

      expect(described_class.coerce(value)).to equal(value)
      expect(described_class.coerce(2)).to eq(decimal("2"))
      expect(described_class.coerce("3.125")).to eq(decimal("3.125"))
      expect(described_class.coerce(Rational(1, 8))).to eq(decimal("0.125"))
    end

    it "rejects binary floats instead of silently rounding them" do
      expect { described_class.coerce(0.1) }
        .to raise_error(SolidusWeightedShipping::ConfigurationError, /exact decimal/)
    end

    it "rejects malformed and non-finite values" do
      [nil, "", "not-a-number", "NaN", "Infinity", "-Infinity"].each do |value|
        expect { described_class.coerce(value) }
          .to raise_error(SolidusWeightedShipping::ConfigurationError)
      end
    end

    it "uses the requested error class and field name" do
      expect do
        described_class.coerce("nope", name: "item weight", error_class: SolidusWeightedShipping::InputError)
      end.to raise_error(SolidusWeightedShipping::InputError, "item weight must be numeric")
    end
  end
end
