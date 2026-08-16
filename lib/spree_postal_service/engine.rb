# frozen_string_literal: true

module SpreePostalService
  class Engine < Rails::Engine
    engine_name "spree_postal_service"

    initializer "spree_postal_service.register_calculator" do |app|
      calculators = app.config.spree.calculators.shipping_methods
      calculator = Spree::Calculator::Shipping::PostalService
      calculators << calculator unless calculators.include?(calculator)
    end
  end
end
