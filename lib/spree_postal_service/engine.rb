# frozen_string_literal: true

require "solidus_core"
require "solidus_support"

module SpreePostalService
  class Engine < Rails::Engine
    include SolidusSupport::EngineExtensions

    isolate_namespace ::Spree

    engine_name "spree_postal_service"

    initializer "spree_postal_service.register_calculator", after: "spree.register.calculators" do |app|
      app.config.spree.calculators.shipping_methods << "Spree::Calculator::Shipping::PostalService"
    end
  end
end
