# frozen_string_literal: true

module SpreePostalService
  class Constraints
    attr_reader :max_item_weight, :max_item_width, :max_item_length, :default_weight

    def initialize(max_item_weight:, max_item_width:, max_item_length:, default_weight:)
      @max_item_weight = positive(max_item_weight, "maximum item weight")
      @max_item_width = positive(max_item_width, "maximum item width")
      @max_item_length = positive(max_item_length, "maximum item length")
      @default_weight = positive(default_weight, "default weight")
      freeze
    end

    def item_allowed?(item)
      effective_weight(item.weight) <= max_item_weight && dimensions_allowed?(item.dimensions)
    end

    private

    def effective_weight(value)
      weight = Decimal.coerce(value || 0, name: "item weight")
      weight.positive? ? weight : default_weight
    end

    def dimensions_allowed?(dimensions)
      values = Array(dimensions).map { |value| Decimal.coerce(value || 0, name: "item dimension") }
      return false if values.any?(&:negative?)

      longest, second_longest = values.sort.reverse
      (longest || 0) <= max_item_length && (second_longest || 0) <= max_item_width
    end

    def positive(value, name)
      decimal = Decimal.coerce(value, name: name)
      raise ConfigurationError, "#{name} must be greater than zero" unless decimal.positive?

      decimal
    end
  end
end
