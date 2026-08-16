# frozen_string_literal: true

module Spree
  module Calculator::Shipping
    class WeightedShipping < ShippingCalculator
      DEFAULT_RATE_TABLE = "1: 6\n2: 9\n5: 12\n10: 15\n20: 18"
      ADMIN_PREFERENCE_NAMES = %i[
        rate_table
        maximum_item_weight
        maximum_item_width
        maximum_item_length
        free_shipping_threshold
        handling_threshold
        handling_fee
        default_item_weight
      ].freeze

      preference :rate_table, :text, default: DEFAULT_RATE_TABLE
      preference :maximum_item_weight, :decimal, default: 18
      preference :maximum_item_width, :decimal, default: 60
      preference :maximum_item_length, :decimal, default: 120
      preference :free_shipping_threshold, :decimal, default: 120
      preference :handling_threshold, :decimal, default: 50
      preference :handling_fee, :decimal, default: 10
      preference :default_item_weight, :decimal, default: 1

      alias_method :write_preferred_rate_table, :preferred_rate_table=
      alias_method :write_preferred_maximum_item_weight, :preferred_maximum_item_weight=
      alias_method :write_preferred_maximum_item_width, :preferred_maximum_item_width=
      alias_method :write_preferred_maximum_item_length, :preferred_maximum_item_length=
      alias_method :write_preferred_free_shipping_threshold, :preferred_free_shipping_threshold=
      alias_method :write_preferred_handling_threshold, :preferred_handling_threshold=
      alias_method :write_preferred_default_item_weight, :preferred_default_item_weight=

      validate :weighted_shipping_configuration
      before_validation :normalize_canonical_rate_table

      def self.description
        I18n.t("spree.weighted_shipping", default: "Weighted Shipping")
      end

      def admin_form_preference_names
        ADMIN_PREFERENCE_NAMES
      end

      def preferred_rate_table=(value)
        clear_legacy_preferences(:weight_table, :price_table)
        write_preferred_rate_table(value)
      end

      def preferred_maximum_item_weight=(value)
        clear_legacy_preferences(:max_item_weight)
        write_preferred_maximum_item_weight(value)
      end

      def preferred_maximum_item_width=(value)
        clear_legacy_preferences(:max_item_width)
        write_preferred_maximum_item_width(value)
      end

      def preferred_maximum_item_length=(value)
        clear_legacy_preferences(:max_item_length)
        write_preferred_maximum_item_length(value)
      end

      def preferred_free_shipping_threshold=(value)
        clear_legacy_preferences(:max_price)
        write_preferred_free_shipping_threshold(value)
      end

      def preferred_handling_threshold=(value)
        clear_legacy_preferences(:handling_max)
        write_preferred_handling_threshold(value)
      end

      def preferred_default_item_weight=(value)
        clear_legacy_preferences(:default_weight)
        write_preferred_default_item_weight(value)
      end

      def legacy_preferences?
        SolidusWeightedShipping::LegacyPreferences.legacy?(preferences)
      end

      def migrate_legacy_preferences!
        migration = SolidusWeightedShipping::LegacyPreferences.migrate(preferences)
        return false unless migration.changed?

        previous_preferences = preferences.dup
        self.preferences = migration.preferences
        policy
        true
      rescue SolidusWeightedShipping::ConfigurationError
        self.preferences = previous_preferences if previous_preferences
        raise
      end

      def quote_package(package)
        policy.quote(package_input(package))
      end

      def available?(package)
        quote_package(package).available?
      rescue SolidusWeightedShipping::ConfigurationError, SolidusWeightedShipping::InputError
        false
      end

      def compute_package(package)
        quote = quote_package(package)
        quote.amount if quote.available?
      rescue SolidusWeightedShipping::ConfigurationError, SolidusWeightedShipping::InputError
        nil
      end

      private

      def policy
        values = policy_values
        signature = policy_signature(values)
        cache = @weighted_shipping_policy_cache
        return cache.last if cache&.first == signature

        rate_table = if values[:legacy_rate_table]
          SolidusWeightedShipping::RateTable.from_legacy(
            thresholds: values[:weight_table],
            prices: values[:price_table]
          )
        else
          SolidusWeightedShipping::RateTable.parse(values[:rate_table])
        end

        calculator = SolidusWeightedShipping::Calculator.new(
          rate_table:,
          constraints: SolidusWeightedShipping::Constraints.new(
            max_item_weight_in_store_units: values[:maximum_item_weight],
            max_item_width_in_store_units: values[:maximum_item_width],
            max_item_length_in_store_units: values[:maximum_item_length],
            default_weight_in_store_units: values[:default_item_weight]
          ),
          free_shipping_threshold_in_currency_units: values[:free_shipping_threshold],
          handling_threshold_in_currency_units: values[:handling_threshold],
          handling_fee_in_currency_units: values[:handling_fee]
        )

        @weighted_shipping_policy_cache = [signature, calculator].freeze
        calculator
      end

      def package_input(package)
        items = package.contents.map do |content_item|
          variant = content_item.variant
          SolidusWeightedShipping::PackageInput::Item.new(
            quantity: content_item.quantity,
            unit_price_in_currency_units: content_item.price,
            weight_in_store_units: variant.weight,
            dimensions_in_store_units: [variant.width, variant.depth, variant.height]
          )
        end

        order_total = package.order&.item_total || items.sum(BigDecimal("0")) do |item|
          item.unit_price_in_currency_units * item.quantity
        end

        SolidusWeightedShipping::PackageInput.new(
          items: items,
          order_merchandise_total: order_total,
          currency: package.currency
        )
      end

      def weighted_shipping_configuration
        policy
      rescue SolidusWeightedShipping::ConfigurationError => error
        errors.add(:base, error.message)
      end

      def normalize_canonical_rate_table
        return if legacy_rate_table?

        normalized = SolidusWeightedShipping::RateTable.parse(preferred_rate_table).dump
        write_preferred_rate_table(normalized) unless normalized == preferred_rate_table
      rescue SolidusWeightedShipping::ConfigurationError
        nil
      end

      def policy_values
        values = {
          maximum_item_weight: configured_preference(:maximum_item_weight, legacy: :max_item_weight),
          maximum_item_width: configured_preference(:maximum_item_width, legacy: :max_item_width),
          maximum_item_length: configured_preference(:maximum_item_length, legacy: :max_item_length),
          free_shipping_threshold: configured_preference(:free_shipping_threshold, legacy: :max_price),
          handling_threshold: configured_preference(:handling_threshold, legacy: :handling_max),
          handling_fee: preferred_handling_fee,
          default_item_weight: configured_preference(:default_item_weight, legacy: :default_weight)
        }

        if legacy_rate_table?
          values.merge(
            legacy_rate_table: true,
            weight_table: stored_preference(:weight_table),
            price_table: stored_preference(:price_table)
          )
        else
          values.merge(legacy_rate_table: false, rate_table: preferred_rate_table)
        end
      end

      def policy_signature(values)
        values.sort_by { |key, _value| key.to_s }.map do |key, value|
          [key, value.class.name, value.to_s].freeze
        end.freeze
      end

      def configured_preference(canonical, legacy:)
        return stored_preference(legacy) if stored_preference?(legacy)

        public_send("preferred_#{canonical}")
      end

      def legacy_rate_table?
        stored_preference?(:weight_table) || stored_preference?(:price_table)
      end

      def stored_preference?(name)
        preferences.key?(name) || preferences.key?(name.to_s)
      end

      def stored_preference(name)
        return preferences.fetch(name) if preferences.key?(name)

        preferences.fetch(name.to_s, nil)
      end

      def clear_legacy_preferences(*names)
        names.each do |name|
          preferences.delete(name)
          preferences.delete(name.to_s)
        end
      end
    end
  end
end
