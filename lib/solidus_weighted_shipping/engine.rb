# frozen_string_literal: true

require "solidus_core"
require "solidus_support"

module SolidusWeightedShipping
  class Engine < Rails::Engine
    include SolidusSupport::EngineExtensions

    isolate_namespace ::Spree

    engine_name "solidus_weighted_shipping"

    initializer "solidus_weighted_shipping.register_calculator", after: "spree.register.calculators" do |app|
      app.config.spree.calculators.shipping_methods << "Spree::Calculator::Shipping::WeightedShipping"
    end
  end
end
