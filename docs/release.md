# Release guide

Solidus Weighted Shipping is maintained as a focused Solidus extension. The
canonical repository is `futhr/solidus-weighted-shipping`; the gem name is
`solidus_weighted_shipping`, and the primary calculator is
`Spree::Calculator::Shipping::WeightedShipping`.

The compatibility require and `Spree::Calculator::Shipping::PostalService`
subclass exist only to help stores migrate. New releases, documentation, and
examples must use the weighted-shipping names.

## Publication status

The rewrite is currently versioned `4.0.0.pre` and has not been published to
RubyGems under its new name. The first stable release will be published as
`solidus_weighted_shipping`; do not publish this code as a new version of the
historical `spree_postal_service` gem.

A gem name is not reserved until RubyGems accepts a publication. Immediately
before release, verify that `solidus_weighted_shipping` is available and that
the releasing account has MFA enabled. If maintainers control the old gem, any
successor or deprecation notice for it is a separate release decision and must
not block publishing the renamed gem.

## Release boundaries

The release includes the deterministic rating policy, Solidus calculator,
legacy preference migration, admin configuration, and supporting documentation.
It does not include carrier APIs, unit conversion, multi-currency rate tables,
labels, tracking, pickup points, a storefront, shipment creation, or a generic
rules engine.

Handling is evaluated per package. Free shipping is based on the whole-order
merchandise total. The complete behavior and migration contract are documented
in the [architecture](architecture.md) and [migration](migration.md) guides.

## Prepare the release

1. Confirm that the GitHub repository is named
   `futhr/solidus-weighted-shipping`, its default branch is `main`, and the old
   repository URL redirects to it.
2. Recheck the supported Ruby, Rails, and Solidus versions against their current
   security status. Review the informational Solidus `main` job separately from
   the supported matrix.
3. Remove expired dependency-audit exceptions. Review the rationale for any
   remaining exception in the [security policy](../SECURITY.md).
4. Move the entries under `Unreleased` in the
   [changelog](../CHANGELOG.md) into a dated stable heading such as
   `[4.0.0] - YYYY-MM-DD`, then add a fresh empty `Unreleased` section.
5. Change `SolidusWeightedShipping::VERSION` from `4.0.0.pre` to the approved
   stable version. Commit the release metadata as one Conventional Commit.

## Run the release gates

Start from a clean checkout and rebuild the disposable Solidus app before
running the complete suite:

```sh
bundle install
bin/sandbox
bin/rake
bundle exec rake quality:coverage
bundle exec rake quality:lint
MUTANT_JOBS=4 bundle exec rake quality:mutation
bundle exec bundle-audit check --update
actionlint .github/workflows/*.yml
```

Run every row in the [supported matrix](testing.md#supported-matrix) from its
own clean dependency resolution. Inspect all eight browser screenshots for
layout, generated-only data, and coherent prices.

## Build and inspect the gem

Build the exact artifact that will be published:

```sh
mkdir -p pkg
gem build solidus_weighted_shipping.gemspec \
  --output pkg/solidus_weighted_shipping.gem
gem specification pkg/solidus_weighted_shipping.gem
```

Confirm that the package contains the expected `app`, `config`, `docs`, and
`lib` files plus the README, changelog, and license. It must not contain the
dummy application, screenshots, coverage data, test-only preview controller,
or legacy gemspec.

Install the artifact into a temporary gem home and load
`solidus_weighted_shipping/domain` with the repository absent from `$LOAD_PATH`.
Inspect the installed gem's runtime graph; only `solidus_core` and
`solidus_support` should be direct runtime dependencies.

## Tag, publish, and verify

1. Confirm that the release commit is clean, reviewed, and passing every
   required check.
2. Create an annotated, immutable tag such as `v4.0.0` on that exact commit.
3. Push `main` and the tag, then publish the inspected gem with RubyGems MFA.
4. Download the published artifact and compare its checksum and metadata with
   the local artifact.
5. Confirm the RubyGems links, GitHub release, changelog comparison links, and
   installation instructions from a clean application.

Never move a published release tag or publish from a dirty tree. Stop the
release if repository routing, gem-name availability, owner access, MFA, the
artifact checksum, or a required compatibility result is uncertain.
