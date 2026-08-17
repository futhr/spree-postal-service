# frozen_string_literal: true

require "bundler/gem_tasks"
require "solidus_dev_support/rake_tasks"

SolidusDevSupport::RakeTasks.install

namespace :quality do
  desc "Run StandardRB and the Solidus RuboCop rules"
  task :lint do
    targets = %w[. bin/rails bin/rails-engine bin/rails-sandbox]
    sh Gem.ruby, "-S", "bundle", "exec", "standardrb", *targets
    sh Gem.ruby, "-S", "bundle", "exec", "rubocop", *targets
  end

  desc "Run the complete suite with line and branch coverage gates"
  task :coverage do
    sh({"COVERAGE" => "true"}, "bin/rake", "extension:specs")
  end

  desc "Mutation-test the high-risk pricing and eligibility decisions"
  task :mutation do
    jobs = ENV.fetch("MUTANT_JOBS", "2")
    common = [
      Gem.ruby, "-S", "bundle", "exec", "mutant", "run",
      "--usage", "opensource",
      "--integration", "rspec",
      "--require", "solidus_weighted_shipping/domain"
    ]

    sh(
      *common,
      "--integration-argument", "spec/solidus_weighted_shipping/rate_table_spec.rb",
      "--jobs", jobs,
      "SolidusWeightedShipping::RateTable#price_for"
    )
    sh(
      *common,
      "--integration-argument", "spec/solidus_weighted_shipping/calculator_spec.rb",
      "--jobs", jobs,
      "SolidusWeightedShipping::Calculator#quote",
      "SolidusWeightedShipping::Calculator#handling_for"
    )
    sh(
      *common,
      "--integration-argument", "spec/solidus_weighted_shipping/constraints_spec.rb",
      "--jobs", jobs,
      "SolidusWeightedShipping::Constraints#eligibility_for"
    )
  end
end

task default: "extension:specs"
