# frozen_string_literal: true

require "solidus_dev_support/rspec/coverage"
require "solidus_weighted_shipping/domain"
require_relative "support/domain_helpers"

RSpec.configure do |config|
  config.filter_run_when_matching :focus
  config.order = :random
  Kernel.srand config.seed
  config.include DomainSpecHelpers
end
