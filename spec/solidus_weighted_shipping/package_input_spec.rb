# frozen_string_literal: true

RSpec.describe SolidusWeightedShipping::PackageInput do
  describe SolidusWeightedShipping::PackageInput::Item do
    it "normalizes exact numeric values and pads missing dimensions" do
      item = weighted_item(quantity: "2", unit_price: "9.99", weight: nil, dimensions: ["12"])

      expect(item.quantity).to eq(2)
      expect(item.unit_price_in_currency_units).to eq(decimal("9.99"))
      expect(item.weight_in_store_units).to be_nil
      expect(item.dimensions_in_store_units).to eq(%w[12 0 0].map { |value| decimal(value) })
      expect(item).to be_frozen
      expect(item.dimensions_in_store_units).to be_frozen
    end

    it "rejects invalid quantities" do
      [0, -1, "1.5", "one", nil].each do |quantity|
        expect { weighted_item(quantity:) }.to raise_error(SolidusWeightedShipping::InputError)
      end
    end

    it "rejects inexact or malformed prices, weights, and dimensions" do
      expect { weighted_item(unit_price: -1) }
        .to raise_error(SolidusWeightedShipping::InputError, /unit price/)
      expect { weighted_item(unit_price: 0.1) }
        .to raise_error(SolidusWeightedShipping::InputError, /exact decimal/)
      expect { weighted_item(weight: "NaN") }
        .to raise_error(SolidusWeightedShipping::InputError, /finite/)
      expect { weighted_item(dimensions: [1, 2, 3, 4]) }
        .to raise_error(SolidusWeightedShipping::InputError, /at most three/)
      expect { weighted_item(dimensions: ["-1"]) }
        .to raise_error(SolidusWeightedShipping::InputError, /must not be negative/)
    end
  end

  describe "package values" do
    it "calculates package merchandise and chargeable weight with quantities" do
      package = weighted_package(
        items: [
          weighted_item(quantity: 2, unit_price: "12.50", weight: "3"),
          weighted_item(quantity: 3, unit_price: "5", weight: nil),
          weighted_item(quantity: 1, unit_price: "10", weight: "0")
        ],
        order_total: "100",
        currency: " eur "
      )

      expect(package.merchandise_total).to eq(decimal("50"))
      expect(package.total_weight(default_weight: "2")).to eq(decimal("14"))
      expect(package.order_merchandise_total).to eq(decimal("100"))
      expect(package.currency).to eq("EUR")
    end

    it "uses the default for negative historical item weights" do
      package = weighted_package(weight: "-3", quantity: 2)

      expect(package.total_weight(default_weight: "1.5")).to eq(decimal("3"))
    end

    it "copies and freezes the item collection" do
      items = [weighted_item]
      package = weighted_package(items:)
      items.clear

      expect(package.items.length).to eq(1)
      expect(package.items).to be_frozen
      expect(package).to be_frozen
      expect { package.items << weighted_item }.to raise_error(FrozenError)
    end

    it "represents an empty package explicitly" do
      package = weighted_package(items: [], order_total: "0")

      expect(package).to be_empty
      expect(package.merchandise_total).to eq(decimal("0"))
      expect(package.total_weight(default_weight: "1")).to eq(decimal("0"))
    end

    it "rejects invalid package data" do
      expect { described_class.new(items: [Object.new], order_merchandise_total: "1", currency: "USD") }
        .to raise_error(SolidusWeightedShipping::InputError, /package items/)
      expect { weighted_package(order_total: "-1") }
        .to raise_error(SolidusWeightedShipping::InputError, /order merchandise total/)
      expect { weighted_package(currency: "US") }
        .to raise_error(SolidusWeightedShipping::InputError, /three-letter/)
      expect { weighted_package(currency: nil) }
        .to raise_error(SolidusWeightedShipping::InputError, /three-letter/)
      expect { weighted_package(items: [], order_total: 0.0) }
        .to raise_error(SolidusWeightedShipping::InputError, /exact decimal/)
    end
  end
end
