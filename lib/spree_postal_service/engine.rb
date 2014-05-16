module SpreePostalService
  class Engine < Rails::Engine
    isolate_namespace Spree
    engine_name 'spree_postal_service'

    config.autoload_paths += %W(#{config.root}/lib)

    initializer 'spree.register.calculators' do |app|
      require 'spree/calculator/shipping/postal_service'
      app.config.spree.calculators.shipping_methods << Spree::Calculator::Shipping::PostalService
    end
  end
end
