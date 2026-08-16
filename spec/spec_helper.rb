# frozen_string_literal: true

ENV["RAILS_ENV"] = "test"

require "solidus_dev_support/rspec/coverage"

dummy_environment = File.expand_path("dummy/config/environment.rb", __dir__)
system("bin/rake extension:test_app") unless File.exist?(dummy_environment)
require dummy_environment

ActiveRecord::Migration.maintain_test_schema!

require "solidus_dev_support/rspec/feature_helper"

Dir[File.expand_path("support/**/*.rb", __dir__)].sort.each { |file| require file }

SolidusDevSupport::TestingSupport::Factories.load_for(SpreePostalService::Engine)

RSpec.configure do |config|
  config.infer_spec_type_from_file_location!
  config.use_transactional_fixtures = false
end
