# Changelog

All notable changes to Solidus Weighted Shipping are recorded here.

The changelog follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/)
and [Semantic Versioning](https://semver.org/spec/v2.0.0.html). Entries use
Conventional Commit-style prefixes so each release can be traced to a clear
product, compatibility, maintenance, or security concern.

Historical releases were cut from version-specific Spree stable branches, not
one linear release branch. Their entries were reconstructed from the preserved
tags, tagged-tree diffs, and original GitHub release notes.

## [Unreleased]

Release candidate: `4.0.0.pre`.

### Breaking changes

- `feat(identity)!`: rename the maintained project, gem, namespace, and primary
  calculator to `solidus-weighted-shipping`, `solidus_weighted_shipping`,
  `SolidusWeightedShipping`, and
  `Spree::Calculator::Shipping::WeightedShipping`.
- `feat(solidus)!`: replace the legacy whole-order calculator with the current
  `Spree::ShippingCalculator#compute_package` and `Spree::Stock::Package`
  integration.
- `feat(config)!`: replace the two positional whitespace tables with one
  validated `maximum weight: price` rate table.

### Added

- `feat(domain)`: add immutable, framework-light rate-table, constraint,
  package-input, calculator, decimal, and quote objects.
- `feat(migration)`: add deterministic legacy preference and STI conversion,
  including dry-run support and per-calculator failure reporting.
- `feat(compat)`: keep the old require path, namespace alias, preference reader,
  and calculator subclass as migration bridges without registering them for new
  shipping methods.
- `test(domain)`: add exhaustive boundary, property, and mutation tests for
  rate selection, overflow parcels, dimensions, free shipping, and handling.
- `test(solidus)`: add real estimator, persistence, multi-package,
  multi-currency, and no-write integration coverage.
- `test(system)`: add eight asserted and inspected admin/customer browser
  screenshots covering the complete weighted-shipping journey.
- `ci(release)`: add the supported Ruby/Rails/Solidus matrix, coverage, lint,
  mutation, browser, package-installation, dependency-review, advisory, and
  Solidus edge jobs.

### Changed

- `refactor(scope)`: rate item weight, dimensions, merchandise value, and
  handling from the quoted package; keep only the free-shipping threshold
  order-scoped.
- `refactor(numeric)`: use exact `BigDecimal` values and reject binary floats,
  non-finite values, and non-terminating rationals.
- `refactor(tooling)`: adopt `solidus_dev_support`, StandardRB, current RSpec,
  a disposable sandbox, GitHub Actions, and a narrowly packaged runtime gem.
- `docs(operations)`: document installation, configuration, architecture,
  migration, rollback, verification, security, troubleshooting, and release.

### Fixed

- `fix(constraints)`: compare the longest and second-longest dimensions
  independently of product orientation.
- `fix(weight)`: apply the fallback weight consistently to missing, zero, and
  negative historical product weights.
- `fix(config)`: reject empty, malformed, duplicate, decreasing, negative, or
  mismatched rate configuration before checkout.
- `fix(runtime)`: make invalid configuration unavailable to the estimator
  instead of raising an arbitrary checkout exception.

### Security

- `security(supply-chain)`: require RubyGems MFA metadata, weekly dependency
  updates, dependency review, and advisory scanning with only documented,
  development-only exceptions.

### Removed

- `chore(legacy)`: remove obsolete Travis, Guard, Hound, Reek, FactoryGirl-era,
  committed-sandbox, and legacy frontend development machinery.

## [3.1.0] - 2017-02-03

### Changed

- `feat(compat)`: add support for the Spree `3-1-stable` line and align the
  runtime and development dependencies with Spree 3.1.
- `chore(tooling)`: update RSpec, Sass, lint, and supported Ruby test versions.

### Fixed

- `fix(weight)`: retain the explicit `weight > 0` fallback check for the
  numeric values returned by supported Spree versions.

## [3.0.0] - 2017-02-03

### Changed

- `feat(compat)`: add support for the Spree `3-0-stable` line.
- `chore(ruby)`: require Ruby 2.1 or newer and test Ruby 2.2.5 and 2.3.1.
- `docs(contributing)`: expand the contributor and development guidance.

## [2.4.0] - 2014-11-28

### Changed

- `feat(compat)`: add support for the Spree `2-4-stable` line by backporting
  the maintained calculator from the development branch.
- `ci(travis)`: move the stable branch to the then-current Travis build
  environment.

## [2.3.1] - 2014-11-22

### Fixed

- `fix(weight)`: use the configured fallback when Spree returns a non-positive
  `BigDecimal` product weight instead of `nil`.

### Changed

- `chore(tooling)`: update lint rules and remove RuboCop from the interactive
  Guard loop where it conflicted with Pry.

## [2.3.0] - 2014-11-21

### Changed

- `feat(compat)`: add support for the Spree `2-3-stable` line.
- `refactor(calculator)`: reorganize the calculator into the Spree shipping
  namespace and split price, weight, index, and handling calculations into
  focused methods without intentionally changing merchant behavior.
- `test(harness)`: modernize RSpec support, database cleanup, factories,
  translation checks, and coverage tooling.
- `chore(quality)`: add the contemporary Hound, RuboCop, Reek, and development
  dependency configuration used by the project at that time.

## [2.2.0] - 2014-04-05

### Changed

- `feat(compat)`: add support for the Spree `2-2-stable` line; no calculator
  behavior change was required.

## [2.1.0] - 2014-04-05

### Changed

- `feat(compat)`: add support for Spree `2-1-stable` and Rails 4.
- `refactor(spree)`: move the class to
  `Spree::Calculator::Shipping::PostalService`, subclass
  `Spree::ShippingCalculator`, and consume package contents through the then-new
  shipping calculator API.
- `test(rspec)`: update the suite toward RSpec 3 syntax.

### Fixed

- `fix(dimensions)`: compare the second-longest side with the configured width
  limit instead of comparing the longest side twice.

## [2.0.1] - 2014-04-05

### Fixed

- `fix(i18n)`: move calculator translations under the Spree namespace and use
  `Spree.t` for Spree 2.0 admin labels.

## [2.0.0] - 2014-04-05

### Changed

- `feat(compat)`: add support for the Spree `2-0-stable` line.
- `test(harness)`: update Spree testing-support paths and dependencies for
  Spree 2.0.
- `chore(runtime)`: remove an unused URL helper dependency.

## [1.3.0] - 2014-04-05

### Changed

- `feat(compat)`: add support for the Spree `1-3-stable` line; no calculator
  behavior change was required.
- `docs(release)`: add RubyGems version information to the README.

## [1.2.0] - 2014-04-05

### Changed

- `feat(compat)`: add support for the Spree `1-2-stable` line; no calculator
  behavior change was required.
- `docs(install)`: switch installation guidance from a Git branch to the
  published gem.

## [1.1.2] - 2014-04-05

### Added

- `release(rubygems)`: publish the first recorded RubyGems release for
  `spree_postal_service`.

### Changed

- `ci(ruby)`: drop Ruby 1.8.7 from CI after dependency-resolution failures in
  its Nokogiri toolchain.

## [1.1.0] - 2014-04-05

Pre-release and first preserved tag.

### Added

- `feat(i18n)`: add Swedish translations and rename the Portuguese locale to
  the Rails-compatible `pt` key.
- `test(backport)`: add the full backported calculator and engine test suite.

### Changed

- `chore(maintenance)`: transfer active maintenance and clean up the engine,
  packaging, formatting, and documentation for Spree 1.1.

[Unreleased]: https://github.com/futhr/solidus-weighted-shipping/compare/v3.1.0...HEAD
[3.1.0]: https://github.com/futhr/solidus-weighted-shipping/releases/tag/v3.1.0
[3.0.0]: https://github.com/futhr/solidus-weighted-shipping/releases/tag/v3.0.0
[2.4.0]: https://github.com/futhr/solidus-weighted-shipping/releases/tag/v2.4.0
[2.3.1]: https://github.com/futhr/solidus-weighted-shipping/releases/tag/v2.3.1
[2.3.0]: https://github.com/futhr/solidus-weighted-shipping/releases/tag/v2.3.0
[2.2.0]: https://github.com/futhr/solidus-weighted-shipping/releases/tag/v2.2.0
[2.1.0]: https://github.com/futhr/solidus-weighted-shipping/releases/tag/v2.1.0
[2.0.1]: https://github.com/futhr/solidus-weighted-shipping/releases/tag/v2.0.1
[2.0.0]: https://github.com/futhr/solidus-weighted-shipping/releases/tag/v2.0.0
[1.3.0]: https://github.com/futhr/solidus-weighted-shipping/releases/tag/v1.3.0
[1.2.0]: https://github.com/futhr/solidus-weighted-shipping/releases/tag/v1.2.0
[1.1.2]: https://github.com/futhr/solidus-weighted-shipping/releases/tag/v1.1.2
[1.1.0]: https://github.com/futhr/solidus-weighted-shipping/releases/tag/v1.1.0
