# frozen_string_literal: true

require_relative "lib/solidus_weighted_shipping/version"

Gem::Specification.new do |spec|
  spec.name = "solidus_weighted_shipping"
  spec.version = SolidusWeightedShipping::VERSION
  spec.authors = ["Torsten Rüger", "Tobias Bohwalli"]
  spec.email = ["torsten@villataika.fi", "hi@futhr.io"]

  spec.summary = "Weighted and parcel-rule shipping calculator for Solidus"
  spec.description = "A deterministic Solidus weighted-shipping calculator with configurable rate bands, parcel constraints, handling fees, and free-shipping thresholds."
  spec.homepage = "https://github.com/futhr/solidus-weighted-shipping"
  spec.license = "BSD-3-Clause"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "#{spec.homepage}/tree/main"
  spec.metadata["changelog_uri"] = "#{spec.homepage}/blob/main/CHANGELOG.md"
  spec.metadata["documentation_uri"] = "#{spec.homepage}/blob/main/README.md"
  spec.metadata["bug_tracker_uri"] = "#{spec.homepage}/issues"
  spec.metadata["rubygems_mfa_required"] = "true"

  spec.required_ruby_version = Gem::Requirement.new(">= 3.2")

  files = Dir.chdir(__dir__) { `git ls-files -z`.split("\x0") }
  spec.files = files.select do |file|
    file.match?(%r{\A(?:app|config|docs|lib)/}) ||
      %w[CHANGELOG.md LICENSE.md README.md].include?(file)
  end
  spec.require_paths = ["lib"]

  spec.add_dependency "solidus_core", ">= 4.6", "< 5"
  spec.add_dependency "solidus_support", ">= 0.12"

  spec.add_development_dependency "solidus_dev_support"
  spec.add_development_dependency "bundler-audit", "~> 0.9"
  spec.add_development_dependency "mutant-rspec", ">= 0.15", "< 0.17"
  spec.add_development_dependency "rantly", ">= 2.0", "< 4"
  spec.add_development_dependency "rspec", "~> 3.13"
  spec.add_development_dependency "standard", "~> 1.56"
end
