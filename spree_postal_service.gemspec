# frozen_string_literal: true

require_relative "lib/spree_postal_service/version"

Gem::Specification.new do |spec|
  spec.name = "spree_postal_service"
  spec.version = SpreePostalService::VERSION
  spec.authors = ["Torsten Rüger", "Tobias Bohwalli"]
  spec.email = ["torsten@villataika.fi", "hi@futhr.io"]

  spec.summary = "Weight and parcel-rule shipping calculator for Solidus"
  spec.description = "A deterministic Solidus shipping calculator with configurable weight bands, parcel constraints, handling fees, and free-shipping thresholds."
  spec.homepage = "https://github.com/futhr/spree-postal-service"
  spec.license = "BSD-3-Clause"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = spec.homepage
  spec.metadata["changelog_uri"] = "#{spec.homepage}/blob/main/CHANGELOG.md"

  spec.required_ruby_version = Gem::Requirement.new(">= 3.2")

  files = Dir.chdir(__dir__) { `git ls-files -z`.split("\x0") }
  spec.files = files.grep_v(%r{^(spec|sandbox)/})
  spec.require_paths = ["lib"]

  spec.add_dependency "solidus_core", ">= 4.6", "< 5"
  spec.add_dependency "solidus_support", ">= 0.12"

  spec.add_development_dependency "solidus_dev_support"
end
