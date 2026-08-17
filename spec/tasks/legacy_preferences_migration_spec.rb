# frozen_string_literal: true

require "rails_helper"
require "rake"

RSpec.describe "solidus_weighted_shipping:preferences:migrate" do
  subject(:task) { Rake::Task["solidus_weighted_shipping:preferences:migrate"] }

  before(:all) do
    Rails.application.load_tasks unless Rake::Task.task_defined?("solidus_weighted_shipping:preferences:migrate")
  end

  before do
    task.reenable
  end

  after do
    Spree::Calculator.unscoped.where(id: calculator_id).delete_all
    ENV.delete("DRY_RUN")
  end

  let(:legacy_preferences) do
    {
      weight_table: "1 2 5",
      price_table: "6 9 12",
      max_item_weight: decimal("18"),
      max_item_width: decimal("60"),
      max_item_length: decimal("120"),
      max_price: decimal("120"),
      handling_max: decimal("50"),
      handling_fee: decimal("10"),
      default_weight: decimal("1")
    }
  end
  let(:legacy_type) { "Spree::Calculator::Shipping::PostalService" }
  let(:canonical_type) { "Spree::Calculator::Shipping::WeightedShipping" }

  let!(:calculator_id) do
    calculator = Spree::Calculator::Shipping::WeightedShipping.create!(preferences: legacy_preferences)
    calculator.update_column(:type, legacy_type)
    calculator.id
  end

  it "persists canonical preferences and the canonical STI type" do
    expect { task.invoke }.to output(/migrated 1 calculator/).to_stdout

    migrated = Spree::Calculator.find(calculator_id)
    expect(migrated).to be_a(Spree::Calculator::Shipping::WeightedShipping)
    expect(migrated.type).to eq(canonical_type)
    expect(migrated.preferences).to include(
      rate_table: "1: 6\n2: 9\n5: 12",
      free_shipping_threshold: decimal("120"),
      handling_threshold: decimal("50")
    )
    expect(migrated).not_to be_legacy_preferences
    expect(migrated).to be_valid
  end

  it "supports a side-effect-free dry run" do
    ENV["DRY_RUN"] = "1"
    original = Spree::Calculator.unscoped.where(id: calculator_id).pick(:type, :preferences)

    expect { task.invoke }.to output(/would migrate 1 calculator/).to_stdout

    expect(Spree::Calculator.unscoped.where(id: calculator_id).pick(:type, :preferences)).to eq(original)
  end

  it "reports already canonical calculators without writing them" do
    Spree::Calculator.unscoped.where(id: calculator_id).delete_all
    canonical = Spree::Calculator::Shipping::WeightedShipping.create!
    updated_at = canonical.updated_at

    expect { task.invoke }.to output(/0 calculator\(s\); 1 already canonical/).to_stdout

    expect(canonical.reload.updated_at).to eq(updated_at)
  ensure
    canonical&.delete
  end

  it "reports invalid calculators by ID and leaves them unchanged" do
    invalid_preferences = legacy_preferences.merge(
      weight_table: "2 1",
      price_table: "6 9"
    )
    Spree::Calculator.unscoped.where(id: calculator_id).update_all(preferences: invalid_preferences)

    expect do
      task.invoke
    end.to output(/calculator #{calculator_id}:.*strictly increasing/m).to_stderr
      .and raise_error(SystemExit, /migration failed for 1 calculator/)

    stored_type, stored_preferences = Spree::Calculator.unscoped
      .where(id: calculator_id)
      .pick(:type, :preferences)
    expect(stored_type).to eq(legacy_type)
    expect(stored_preferences).to eq(invalid_preferences)
  end

  it "validates a type-only conversion before committing it" do
    invalid_preferences = {rate_table: "2: 6\n1: 9"}
    Spree::Calculator.unscoped.where(id: calculator_id).update_all(preferences: invalid_preferences)

    expect do
      task.invoke
    end.to output(/calculator #{calculator_id}:.*strictly increasing/m).to_stderr
      .and raise_error(SystemExit, /migration failed for 1 calculator/)

    stored_type, stored_preferences = Spree::Calculator.unscoped
      .where(id: calculator_id)
      .pick(:type, :preferences)
    expect(stored_type).to eq(legacy_type)
    expect(stored_preferences).to eq(invalid_preferences)
  end
end
