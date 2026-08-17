# frozen_string_literal: true

namespace :solidus_weighted_shipping do
  namespace :preferences do
    desc "Migrate legacy Spree Postal Service preferences and calculator types"
    task migrate: :environment do
      dry_run = ENV["DRY_RUN"] == "1"
      migrated = 0
      unchanged = 0
      failures = []
      legacy_type = "Spree::Calculator::Shipping::PostalService"
      canonical_type = "Spree::Calculator::Shipping::WeightedShipping"
      calculator_ids = Spree::Calculator.unscoped.where(type: [legacy_type, canonical_type]).ids

      calculator_ids.each do |calculator_id|
        outcome = nil

        Spree::Calculator.transaction(requires_new: true) do
          row = Spree::Calculator.unscoped.where(id: calculator_id).lock
          stored_type = row.pick(:type)
          next unless stored_type

          type_changed = stored_type != canonical_type
          row.update_all(type: canonical_type) if type_changed

          calculator = Spree::Calculator::Shipping::WeightedShipping.find(calculator_id)
          preferences_changed = calculator.migrate_legacy_preferences!
          outcome = (preferences_changed || type_changed) ? :migrated : :unchanged

          if outcome == :migrated
            raise ActiveRecord::RecordInvalid.new(calculator) unless calculator.valid?

            calculator.save! unless dry_run
          end

          raise ActiveRecord::Rollback if dry_run && outcome == :migrated
        end

        migrated += 1 if outcome == :migrated
        unchanged += 1 if outcome == :unchanged
      rescue => error
        failures << "calculator #{calculator_id}: #{error.class}: #{error.message}"
      end

      action = dry_run ? "would migrate" : "migrated"
      puts "#{action} #{migrated} calculator(s); #{unchanged} already canonical"

      next if failures.empty?

      failures.each { |failure| warn failure }
      abort "legacy preference migration failed for #{failures.length} calculator(s)"
    end
  end
end
