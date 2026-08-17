# frozen_string_literal: true

RSpec.describe "the packaged gem" do
  subject(:specification) do
    Gem::Specification.load(File.expand_path("../../solidus_weighted_shipping.gemspec", __dir__))
  end

  it "publishes the canonical weighted-shipping identity" do
    expect(specification.name).to eq("solidus_weighted_shipping")
    expect(specification.version.to_s).to eq(SolidusWeightedShipping::VERSION)
    expect(specification.homepage).to eq("https://github.com/futhr/solidus-weighted-shipping")
    expect(specification.metadata["source_code_uri"]).to end_with("/tree/main")
    expect(specification.metadata["documentation_uri"]).to end_with("/blob/main/docs/README.md")
    expect(specification.metadata).to include(
      "allowed_push_host" => "https://rubygems.org",
      "rubygems_mfa_required" => "true"
    )
  end

  it "contains runtime code and documentation without test or generated files" do
    expect(specification.files).to include(
      "lib/solidus_weighted_shipping.rb",
      "lib/solidus_weighted_shipping/domain.rb",
      "app/models/spree/calculator/shipping/weighted_shipping.rb",
      "README.md",
      "docs/README.md",
      "docs/architecture.md",
      "docs/migration.md",
      "docs/release.md",
      "docs/security.md",
      "docs/testing.md",
      "docs/troubleshooting.md"
    )
    expect(specification.files.grep(/spree_postal_service/)).to be_empty
    expect(specification.files).not_to include("spree_postal_service.gemspec")
    expect(specification.files.grep(%r{\A(?:spec|sandbox|tmp)/})).to be_empty
  end

  it "declares only the narrow runtime dependencies" do
    dependencies = specification.runtime_dependencies.to_h { |dependency| [dependency.name, dependency.requirement.to_s] }

    expect(dependencies).to eq(
      "solidus_core" => ">= 4.6, < 5",
      "solidus_support" => ">= 0.12"
    )
  end
end
