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
    Spree::Calculator.where(id: calculator&.id).delete_all
    ENV.delete("DRY_RUN")
  end

  let!(:calculator) do
    Spree::Calculator.create!(
      type: "Spree::Calculator::Shipping::PostalService",
      preferences: {
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
    )
  end

  it "persists canonical preferences and the canonical STI type" do
    expect { task.invoke }.to output(/migrated 1 calculator/).to_stdout

    migrated = Spree::Calculator.find(calculator.id)
    expect(migrated).to be_a(Spree::Calculator::Shipping::WeightedShipping)
    expect(migrated).not_to be_a(Spree::Calculator::Shipping::PostalService)
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

    expect { task.invoke }.to output(/would migrate 1 calculator/).to_stdout

    unchanged = Spree::Calculator.find(calculator.id)
    expect(unchanged).to be_a(Spree::Calculator::Shipping::PostalService)
    expect(unchanged).to be_legacy_preferences
  end
end
