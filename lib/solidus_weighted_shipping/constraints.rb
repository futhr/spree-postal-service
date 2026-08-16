# frozen_string_literal: true

module SolidusWeightedShipping
  class Constraints
    Eligibility = Data.define(:status, :reason) do
      def eligible?
        status == :eligible
      end
    end

    ELIGIBLE = Eligibility.new(status: :eligible, reason: nil)

    attr_reader :max_item_weight_in_store_units,
      :max_item_width_in_store_units,
      :max_item_length_in_store_units,
      :default_weight_in_store_units

    def initialize(
      max_item_weight_in_store_units:,
      max_item_width_in_store_units:,
      max_item_length_in_store_units:,
      default_weight_in_store_units:
    )
      @max_item_weight_in_store_units = positive(max_item_weight_in_store_units, "maximum item weight")
      @max_item_width_in_store_units = positive(max_item_width_in_store_units, "maximum item width")
      @max_item_length_in_store_units = positive(max_item_length_in_store_units, "maximum item length")
      @default_weight_in_store_units = positive(default_weight_in_store_units, "default weight")
      freeze
    end

    def item_allowed?(item)
      eligibility_for(item).eligible?
    end

    def eligibility_for(item)
      unless item.is_a?(PackageInput::Item)
        raise InputError, "item must be a SolidusWeightedShipping::PackageInput::Item value"
      end

      if effective_weight_for(item) > max_item_weight_in_store_units
        return Eligibility.new(status: :ineligible, reason: :maximum_item_weight_exceeded)
      end

      longest, second_longest = item.dimensions_in_store_units.sort.reverse
      if longest > max_item_length_in_store_units
        return Eligibility.new(status: :ineligible, reason: :maximum_item_length_exceeded)
      end
      if second_longest > max_item_width_in_store_units
        return Eligibility.new(status: :ineligible, reason: :maximum_item_width_exceeded)
      end

      ELIGIBLE
    end

    def package_eligibility(package)
      unless package.is_a?(PackageInput)
        raise InputError, "package must be a SolidusWeightedShipping::PackageInput value"
      end

      package.items.each do |item|
        eligibility = eligibility_for(item)
        return eligibility unless eligibility.eligible?
      end

      ELIGIBLE
    end

    def effective_weight_for(item)
      weight = item.weight_in_store_units
      weight&.positive? ? weight : default_weight_in_store_units
    end

    private

    def positive(value, name)
      decimal = Decimal.coerce(value, name: name)
      raise ConfigurationError, "#{name} must be greater than zero" unless decimal.positive?

      decimal
    end
  end
end
