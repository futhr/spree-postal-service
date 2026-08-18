# Final audit record

Audit date: 17 August 2026.

## Decision

Maintain. The extension fills a verified Solidus ecosystem gap with a narrow,
deterministic shipping policy and does not duplicate carrier or fulfillment
systems.

## Final repository name

`futhr/solidus-weighted-shipping`. The rename is complete and the canonical URL
is used in package and installation metadata.

## Gem namespace

`solidus_weighted_shipping`. The new gem exposes no legacy require, namespace,
or calculator constant. The new gem name was not published on RubyGems when
checked on the audit date; availability must be checked again at publication
time.

## Evidence

- Pure Ruby policy objects own parsing, exact decimal arithmetic, eligibility,
  parcel decomposition, and quote state.
- The Solidus adapter uses public shipping calculator/package/estimator seams
  and performs no override or monkey patch.
- Configuration validation fails closed in estimation and appears in the real
  Solidus admin form.
- The extension owns no network, secret, PII, controller, route, table, carrier,
  tracking, label, or shipment-lifecycle behavior.

## Compatibility

- Ruby 3.2 or newer.
- Solidus 4.7 primary; Solidus 4.6 secondary while security-supported.
- Rails/Solidus combinations are declared and exercised by the CI matrix in
  [testing.md](testing.md#supported-matrix).
- Solidus 4.5 and earlier are intentionally unsupported.

## Migration

The deterministic preference/STI migration, dry run, failure isolation,
deployment order, and one-way rollback implication are documented in
[migration.md](migration.md).

## RubyGems ownership

On the audit date, RubyGems reported `spree_postal_service` 2.4.0 with 27,814
downloads and owner `futhr`. The historical versions and Git tags remain
available; do not yank or publish another old-name release merely for symmetry.
RubyGems returned 404 for `solidus_weighted_shipping`, so the new name was
available but not reserved. A pending Trusted Publisher for the new gem,
maintainer MFA, and protected `release` environment cannot be proved from a
source checkout and remain release gates.

## GitHub operations

The repository rename and history reconciliation are complete. Commit
`30ac47c` records the ancestry-preserving merge. A follow-up verification on 18
August 2026 confirmed that:

- `main` is the default branch and is synchronized with `origin/main`;
- the repository description and topics describe the maintained Solidus gem;
- private vulnerability reporting is enabled; and
- historical pull request #3 is closed.

GitHub still reports no protection on `main`, no repository rulesets, and no
`release` environment. Secret scanning and push protection are also disabled.
These are current publication gates, along with RubyGems Trusted Publisher
ownership and maintainer MFA; the completed history merge must not be repeated.

## Provider/API status

Not applicable. This extension makes no provider or HTTP calls.

## Test evidence

Required evidence comprises the supported CI matrix, line/branch coverage,
selected mutation targets, a clean generated Solidus application, real
estimator/persistence integration, package installation, dependency audit, and
eight semantically asserted browser screenshots. Exact commands are listed in
[testing.md](testing.md#one-shot-verification).

## Known limitations

- Weight and dimension values use store units; the gem does not convert units.
- Rate amounts use decimal order-currency units; one calculator does not hold
  separate tables per currency.
- Browser evidence uses a test-only estimator preview because the extension
  intentionally does not package a storefront.
- Branch/environment/tag protection, secret scanning and push protection,
  RubyGems Trusted Publisher/MFA, and green remote checks on the exact release
  commit require authorized external configuration.

## Release action

Do not publish `4.0.0` until every external gate above is confirmed, the full
matrix is green on the exact candidate commit, all eight screenshots are
inspected, and the workflow-retained gem checksum matches the subsequently
downloaded RubyGems artifact.
