# Release guide

Solidus Weighted Shipping is maintained as a focused Solidus extension. The
repository is `futhr/solidus-weighted-shipping`. The gem name is
`solidus_weighted_shipping`, and the primary calculator is
`Spree::Calculator::Shipping::WeightedShipping`.

The new gem does not expose the historical require, namespace, or calculator
class. Legacy names remain only as data values recognized by the explicit
migration task.

## Publication status

The rewrite is currently versioned `4.0.0.pre` and has not been published to
RubyGems under its new name. The first stable release will be published as
`solidus_weighted_shipping`; do not publish this code as a new version of the
historical `spree_postal_service` gem.

A gem name is not reserved until RubyGems accepts a publication. Immediately
before release, verify that `solidus_weighted_shipping` is available and that
the releasing account has MFA enabled. RubyGems lists `futhr` as owner of the
old gem; the audit decision is to leave those historical releases untouched
rather than publish a cosmetic deprecation release.

The audit performed on 17 August 2026 found no published
`solidus_weighted_shipping` package, but that observation does not reserve the
name. The repository rename is complete. See the
[final-audit record](final-audit.md) for the remaining external gates.

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

1. Protect `main` with required CI and security checks, blocked force pushes,
   and blocked deletion. Add a `v*` tag ruleset that blocks tag updates and
   deletion after publication.
2. Create a protected GitHub environment named `release` with a maintainer
   approval rule.
3. Configure a pending RubyGems Trusted Publisher for gem
   `solidus_weighted_shipping`, owner `futhr`, repository
   `solidus-weighted-shipping`, workflow `release.yml`, and environment
   `release`. Do not store a long-lived RubyGems API token in GitHub.
4. Confirm that the historical GitHub URL redirects to the renamed repository.
5. Recheck the supported Ruby, Rails, and Solidus versions against their current
   security status. Review the informational Solidus `main` job separately from
   the supported matrix.
6. Remove expired dependency-audit exceptions. Review the rationale for any
   remaining exception in the [security policy](../SECURITY.md).
7. Move the entries under `Unreleased` in the
   [changelog](../CHANGELOG.md) into a dated stable heading such as
   `[4.0.0] - YYYY-MM-DD`, then add a fresh empty `Unreleased` section.
8. Change `SolidusWeightedShipping::VERSION` from `4.0.0.pre` to the approved
   stable version. Replace the README's release-candidate badge with the
   dynamic RubyGems version and download badges. Commit the release metadata as
   one Conventional Commit.

## Completed repository preparation

The one-off history reconciliation was completed by commit `30ac47c` and is
preserved in the repository graph. As verified on 18 August 2026, `main` is the
GitHub default branch and local `main` is synchronized with `origin/main`.
Maintainers must not repeat the reconciliation merge.

The remaining repository-side release gates are protection for `main`, an
immutable `v*` tag ruleset, and a protected `release` environment. RubyGems
Trusted Publisher ownership and maintainer MFA must also be confirmed before
the first publication.

## Run the release gates

Start from a clean checkout and rebuild the disposable Solidus app before
running the complete suite:

```sh
bin/setup
bin/sandbox
bin/rake
bin/rake quality:coverage
bin/rake quality:lint
MUTANT_JOBS=4 bin/rake quality:mutation
ruby -S bundle exec bundle-audit check --update
actionlint .github/workflows/*.yml
```

Run every row in the [supported matrix](testing.md#supported-matrix) from its
own clean dependency resolution. Inspect all eight browser screenshots for
layout, generated-only data, and coherent prices.

## Build and inspect the gem

Build and inspect a candidate artifact from the exact release commit:

```sh
mkdir -p pkg
ruby -S gem build solidus_weighted_shipping.gemspec \
  --output pkg/solidus_weighted_shipping.gem
ruby -S gem specification pkg/solidus_weighted_shipping.gem
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

1. Confirm that the release commit is clean, reviewed, pushed to `main`, and
   passing every required check.
2. Create an annotated, immutable tag such as `v4.0.0` on that exact commit.
3. Push the tag. The `Release` workflow rejects a version mismatch, prerelease
   version, or commit outside `main`, reruns the high-value gates, and publishes
   through short-lived OIDC credentials after `release` environment approval.
4. Download the workflow's retained gem and checksum, then confirm the RubyGems
   download is byte-for-byte identical to that published artifact.
5. Create the GitHub release from the immutable tag and attach the retained gem
   and checksum.
6. Confirm the RubyGems links, GitHub release, changelog comparison links, and
   installation instructions from a clean application.

Never move a published release tag or publish from a dirty tree. Stop the
release if repository routing, gem-name availability, owner access, MFA, the
artifact checksum, or a required compatibility result is uncertain.
