
class SpreePostalService < Rails::Engine

    config.autoload_paths += %W(#{config.root}/lib)

    def self.activate
      Dir.glob(File.join(File.dirname(__FILE__), "../app/**/*_decorator*.rb")) do |c|
        Rails.env.production? ? require(c) : load(c)
      end
    end

    config.to_prepare &method(:activate).to_proc

    initializer "spree.register.calculators" do |app|
      require 'calculator/postal_service'

      app.config.spree.calculators.shipping_methods << Calculator::PostalService 
    end
end
