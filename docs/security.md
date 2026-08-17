# Security and reliability

This gem has a deliberately small attack surface. Runtime code makes no network
requests, owns no controller or route, stores no secrets or personal data, and
adds no tables. The inputs it must distrust are merchant configuration and the
product, package, and order values supplied by the host Solidus application.

## Threat model and controls

Malformed rates, negative values, non-finite numerics, duplicate/decreasing
thresholds, excessive band counts, invalid quantities, and ambiguous binary
Floats are rejected at parsing/construction. The adapter reports configuration
errors through model validation and fails closed during estimation, so one bad
method disappears instead of crashing checkout or returning an arbitrary cost.

Money and physical comparisons use `BigDecimal`. Input objects and quote values
are copied/frozen, rating does not modify caller-owned collections, and
integration tests subscribe to SQL notifications to prove estimation performs
no insert, update, or delete.

The public rate table is bounded to 1,000 bands. The algorithm is local and
linear in configured bands/package contents; it does not evaluate code,
interpolate SQL, dereference URLs, or create shipments from logical parcel
chunks.

Solidus owns admin authentication, authorization, CSRF, zones, and shipping
method persistence. The gem adds preferences to the existing calculator form
and no independent privileged endpoint.

## Data handling

Runtime calculation reads only quantities, prices, weight, three dimensions,
order merchandise total, and currency. It does not read names, email, address,
payment data, tracking data, or credentials. No raw package/order payload is
logged or persisted.

The customer preview controller used by system tests is under `spec/support`,
is mounted only by `spec/rails_helper`, and is excluded from the packaged gem.
Applications must not copy it into production as a storefront endpoint.

## Supply chain

The published runtime graph is limited to `solidus_core` and
`solidus_support`. GitHub Actions runs Bundler Audit, dependency review, lint,
tests, browser evidence, and package installation. Dependabot checks Bundler
and Actions weekly. Every action is pinned to a reviewed commit SHA. Gem
metadata requires MFA and restricts its push host to RubyGems.org; the release
workflow uses short-lived OIDC Trusted Publishing credentials from a protected
GitHub environment instead of a stored API token.

The two temporary Puma audit exceptions are documented in `SECURITY.md` and
`.bundler-audit.yml`. Puma is development-only through `solidus_dev_support`,
the affected PROXY protocol is not enabled, and Puma is absent from the built
gem runtime graph. Remove both exceptions as soon as upstream permits a patched
Puma; never broaden them.

## Reporting and release review

Report vulnerabilities privately as described in the
[security policy](../SECURITY.md). Before a release, update the advisory
database, inspect the runtime dependency graph, review all eight screenshots
for unexpected data, verify current supported Ruby/Solidus lines, and confirm
RubyGems owners and MFA using maintainer credentials.
