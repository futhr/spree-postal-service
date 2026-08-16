# frozen_string_literal: true

module SolidusWeightedShipping
  class LegacyPreferences
    Migration = Data.define(:preferences, :migrated_keys) do
      def changed?
        migrated_keys.any?
      end
    end

    RATE_KEYS = %i[weight_table price_table].freeze
    SCALAR_KEYS = {
      max_item_weight: :maximum_item_weight,
      max_item_width: :maximum_item_width,
      max_item_length: :maximum_item_length,
      max_price: :free_shipping_threshold,
      handling_max: :handling_threshold,
      default_weight: :default_item_weight
    }.freeze
    LEGACY_KEYS = (RATE_KEYS + SCALAR_KEYS.keys).freeze

    def self.legacy?(preferences)
      LEGACY_KEYS.any? { |key| key?(preferences, key) }
    end

    def self.migrate(preferences)
      source = preferences.to_h
      migrated = source.dup
      migrated_keys = []

      if RATE_KEYS.any? { |key| key?(source, key) }
        migrated[:rate_table] = RateTable.from_legacy(
          thresholds: fetch(source, :weight_table),
          prices: fetch(source, :price_table)
        ).dump
        RATE_KEYS.each { |key| delete(migrated, key) }
        migrated_keys.concat(RATE_KEYS)
      end

      SCALAR_KEYS.each do |legacy_key, canonical_key|
        next unless key?(source, legacy_key)

        migrated[canonical_key] = fetch(source, legacy_key)
        delete(migrated, legacy_key)
        migrated_keys << legacy_key
      end

      Migration.new(preferences: migrated, migrated_keys: migrated_keys.freeze)
    end

    def self.key?(preferences, key)
      preferences.key?(key) || preferences.key?(key.to_s)
    end
    private_class_method :key?

    def self.fetch(preferences, key)
      return preferences.fetch(key) if preferences.key?(key)

      preferences.fetch(key.to_s, nil)
    end
    private_class_method :fetch

    def self.delete(preferences, key)
      preferences.delete(key)
      preferences.delete(key.to_s)
    end
    private_class_method :delete
  end
end
