# frozen_string_literal: true

require "simplecov"

SimpleCov.enable_coverage :branch
SimpleCov.start("rails") do
  add_filter %r{^/lib/generators/.*/install/install_generator.rb}
  add_filter %r{^/lib/.*/factories.rb}
  add_filter %r{^/lib/.*/version.rb}
  add_group "Domain", "lib/solidus_weighted_shipping"
  add_group "Solidus adapter", "app/models/spree/calculator/shipping"

  if ENV["COVERAGE"] == "true"
    minimum_coverage line: 95, branch: 85
    minimum_coverage_by_file 70
  end
end

require "solidus_weighted_shipping/domain"
require_relative "support/domain_helpers"

RSpec.configure do |config|
  config.filter_run_when_matching :focus
  config.order = :random
  Kernel.srand config.seed
  config.include DomainSpecHelpers
end
