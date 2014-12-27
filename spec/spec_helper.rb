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

ENV['RAILS_ENV'] ||= 'test'

require File.expand_path('../dummy/config/environment.rb',  __FILE__)

require 'pry'
require 'ffaker'
require 'rspec/rails'

ActiveRecord::Migration.maintain_test_schema!
ActiveRecord::Migration.check_pending!

RSpec.configure do |config|
  config.fail_fast = false
  config.filter_run focus: true
  config.run_all_when_everything_filtered = true

  config.mock_with :rspec
  config.raise_errors_for_deprecations!
  config.infer_spec_type_from_file_location!

  config.expect_with :rspec do |expectations|
    expectations.syntax = :expect
  end
end

Dir[File.join(File.dirname(__FILE__), 'support/**/*.rb')].each { |file| require file }
