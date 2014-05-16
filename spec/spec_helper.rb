require 'simplecov'
require 'coveralls'
SimpleCov.formatter = SimpleCov::Formatter::MultiFormatter[
  SimpleCov::Formatter::HTMLFormatter,
  Coveralls::SimpleCov::Formatter
]
SimpleCov.start do
  add_filter '/.bundle'
  add_filter '/spec/'
  add_filter '/lib/spree_postal_service/engine'
  add_group 'Libraries', 'lib'
end

ENV['RAILS_ENV'] = 'test'

require File.expand_path('../dummy/config/environment.rb',  __FILE__)

require 'ffaker'
require 'rspec/rails'
require 'i18n-spec'

Dir[Rails.root.join('spec/support/**/*.rb')].each {|f| require f}

require 'spree/testing_support/factories'

RSpec.configure do |config|
  config.mock_with :rspec
  config.use_transactional_fixtures = true

  config.include FactoryGirl::Syntax::Methods
end
