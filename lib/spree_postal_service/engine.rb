module SpreePostalService
  class Engine < Rails::Engine
    engine_name 'spree_postal_service'

    config.autoload_paths += %W(#{config.root}/lib)

    initializer 'spree.register.calculators' do |app|
      require 'spree/calculator/postal_service'

      app.config.spree.calculators.shipping_methods << Spree::Calculator::PostalService
    end
  end
end