# Troubleshooting

## The shipping method is absent

Confirm the shipping method is enabled for the order's store, zone, stock
location, shipping category, and user visibility. Then validate its calculator
in Solidus admin. Weighted Shipping intentionally returns unavailable when any
package item exceeds maximum item weight, longest side, or second-longest side,
or when configuration/input cannot be parsed safely.

The longest and second-longest physical dimensions are used regardless of how
width, depth, and height are oriented. Missing dimensions are zero; missing,
zero, or negative item weight uses `default_item_weight`.

## The rate differs from the expected band

Each row is `maximum weight: decimal price`. A band includes its maximum, so a
weight of exactly `2` uses the `2` band and `2.01` uses the next band. Weight
above the final band is priced as repeated final-band parcels plus a remainder.

Handling is package-scoped and applies at or below `handling_threshold`. Free
shipping is order-scoped and applies only when order merchandise total is
strictly greater than `free_shipping_threshold`. Equality is charged in both
legacy-compatible boundary decisions.

Check that product weight/dimension values and calculator thresholds use the
same store units. The gem performs no hidden kg/lb or cm/in conversion.

## Admin rejects the rate table

The table must contain 1–1,000 lines, each with exactly one colon, a positive
threshold, and a non-negative price. Thresholds must be strictly increasing;
blank lines and insignificant whitespace are canonicalized. Floats supplied by
Ruby code are rejected—use decimal strings or `BigDecimal`.

## Legacy calculators do not load or migrate

Ensure the application depends on `solidus_weighted_shipping` and does not
suppress its engine initializer. `require "spree_postal_service"` and the old
STI class remain as temporary load bridges.

Run:

```sh
DRY_RUN=1 bin/rake solidus_weighted_shipping:preferences:migrate
```

An incomplete pair of `weight_table`/`price_table`, unequal list lengths,
unsorted thresholds, or invalid historical value is reported and left
unchanged. Correct that calculator and repeat the dry run before writing.

## A compatibility bundle resolves the wrong Rails version

Export both variables before `bundle install` and rebuild the dummy app:

```sh
RAILS_VERSION=7.0 SOLIDUS_BRANCH=v4.6 bundle install
RAILS_VERSION=7.0 SOLIDUS_BRANCH=v4.6 bin/rake clobber extension:test_app
```

The repository lockfile is intentionally ignored for gem development. Do not
reuse a bundle resolved for another Ruby ABI without reinstalling.

## Browser specs fail locally

Install a current Chrome/Chromium compatible with Selenium, rebuild the dummy
app, and run `bundle exec rspec spec/system`. Failure screenshots are written
under `tmp/screenshots`; server output remains under the disposable dummy app.

## Bundler Audit reports Puma

Only CVE-2026-47736 and CVE-2026-47737 are temporarily scoped out for the
development-only Puma constrained by `solidus_dev_support`. Any other advisory
is a failure. Recheck the upstream constraint before every release and remove
the exceptions once Puma 7.2.1+ or 8.0.2+ can resolve.
