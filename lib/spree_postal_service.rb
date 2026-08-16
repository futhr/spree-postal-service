# frozen_string_literal: true

require "solidus_weighted_shipping"

SpreePostalService = SolidusWeightedShipping unless defined?(SpreePostalService)
