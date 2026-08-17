# Testing

The suite treats tests as the executable contract for the rewrite. A clean
checkout needs Ruby, Bundler, a browser supported by Selenium, and SQLite; the
repository supplies the disposable Solidus application.

## One-shot verification

```sh
bin/setup
bin/sandbox
bin/rake
bin/rails runner 'puts SolidusWeightedShipping::VERSION'
bin/rake quality:coverage
bin/rake quality:lint
bin/rake quality:mutation
ruby -S bundle exec bundle-audit check --update
```

`bin/sandbox` removes and rebuilds `spec/dummy`; it does not create a committed
sandbox. `bin/rake` runs the complete RSpec suite.

## Test layers

- Pure unit specs cover decimal coercion, structured/legacy table parsing,
  every band boundary, overflow parcels, constraints, immutable inputs/results,
  free shipping, handling, empty packages, and invalid states.
- Rantly properties cover non-negative quotes, orientation invariance,
  monotonic tables, and conservation across parcel decomposition.
- Mutant targets the exact pricing, free-shipping, handling, and eligibility
  decisions. Every generated mutant must be killed.
- Solidus integration specs use real records and `Spree::Stock::Estimator` to
  prove registration, preference persistence, package scoping, multiple
  packages, JPY/KWD decimal behavior, and zero SQL writes while rating.
- System specs use the real Solidus admin and an isolated, test-only customer
  preview. The disposable app is generated with `FRONTEND=none`, so the preview
  provides a stable customer-facing view without pretending to be a packaged
  storefront. Its controller lives under `spec/`, is excluded from the gem,
  and still rates through the real estimator.
- Packaging specs inspect the built file set, metadata, and runtime dependency
  graph.

## Coverage gates

With `COVERAGE=true`, SimpleCov requires at least 95% line coverage, 85% branch
coverage, and 70% per source file. Generated dummy files are excluded. The
quality job always retains its LCOV output as a workflow artifact. After the
Codecov GitHub app is granted access to the repository and the repository is
set up in Codecov, set the GitHub Actions repository variable
`CODECOV_ENABLED=true` to enable strict OIDC uploads; no long-lived upload token
is stored. Codecov then requires 95% project and patch coverage in addition to
the local gates. Coverage is diagnostic: boundary and mutation evidence remain
the correctness gate.

## Supported matrix

CI verifies Ruby 3.2/Rails 7.0/Solidus 4.6, Ruby 3.4/Rails 7.2 on Solidus 4.6
and 4.7, and Ruby 4.0/Rails 8.1/Solidus 4.7. A Solidus `main` job is
informational and may fail without blocking a release.

Mutation analysis runs on Ruby 3.3, the newest Ruby grammar supported by its
parser. The compatibility matrix independently exercises the maintained Ruby
3.2, 3.4, and 4.0 runtimes.

The tag-only release workflow is intentionally separate. It accepts only a
stable tag matching the gem version on a commit contained in `main`, reruns
coverage, style, mutation, and dependency-audit gates, then uses RubyGems
Trusted Publishing from the protected `release` environment.

Set `RAILS_VERSION` and `SOLIDUS_BRANCH` before resolving the bundle. The
Gemfile pins the requested Rails minor so a `7.0` job cannot silently resolve
to Rails 7.2.

When reproducing a row locally, apply both variables to dependency resolution,
the dummy-app rebuild, and the spec command. The
[contributing guide](../CONTRIBUTING.md#reproduce-a-compatibility-row) includes
a complete example.

## Browser evidence

The system suite writes these artifacts after semantic assertions pass:

```text
01-admin-calculator-config.png
02-checkout-normal-rate.png
03-checkout-threshold-rate.png
04-checkout-oversized-unavailable.png
05-checkout-free-shipping.png
06-checkout-multi-package.png
07-admin-completed-order-rate.png
08-admin-invalid-config.png
```

CI retains the screenshots for 14 days. They contain generated factory data
only and must be visually inspected before a release.

## Reproducibility

RSpec prints its random seed. Re-run a failure with `--seed <number>`. Tests do
not depend on provider uptime, external credentials, wall-clock sleeps, or a
committed database. Changing Rails/Solidus lines requires a clean dummy rebuild.
