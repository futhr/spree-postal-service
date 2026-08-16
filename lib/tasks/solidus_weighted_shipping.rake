# frozen_string_literal: true

namespace :solidus_weighted_shipping do
  namespace :preferences do
    desc "Migrate legacy Spree Postal Service preferences and calculator types"
    task migrate: :environment do
      dry_run = ENV["DRY_RUN"] == "1"
      migrated = 0
      unchanged = 0
      failures = []
      calculator_types = [
        "Spree::Calculator::Shipping::PostalService",
        "Spree::Calculator::Shipping::WeightedShipping"
      ]

      Spree::Calculator.where(type: calculator_types).find_each do |calculator|
        calculator.with_lock do
          preferences_changed = calculator.migrate_legacy_preferences!
          type_changed = calculator.type != "Spree::Calculator::Shipping::WeightedShipping"

          unless preferences_changed || type_changed
            unchanged += 1
            next
          end

          calculator.type = "Spree::Calculator::Shipping::WeightedShipping"
          calculator.save! unless dry_run
          migrated += 1
        end
      rescue => error
        failures << "calculator #{calculator.id}: #{error.class}: #{error.message}"
      end

      action = dry_run ? "would migrate" : "migrated"
      puts "#{action} #{migrated} calculator(s); #{unchanged} already canonical"

      next if failures.empty?

      failures.each { |failure| warn failure }
      abort "legacy preference migration failed for #{failures.length} calculator(s)"
    end
  end
end
