# Solidus Weighted Shipping

Weight- and parcel-rule shipping for modern Solidus.

This repository preserves the history of the original Spree extension while
`main` carries the current Solidus rewrite. The historical `master` branch and
all existing tags remain untouched.

The rewrite is currently versioned `4.0.0.pre`. It is being prepared for its
first RubyGems release as `solidus_weighted_shipping`; until that release is
published, install it from the renamed GitHub repository.

## What it does

`solidus_weighted_shipping` adds one Solidus shipping calculator with:

- configurable weight bands and prices;
- maximum per-item weight;
- longest-side and second-longest-side limits independent of orientation;
- fallback weight for products without a positive weight;
- repeated maximum-band charging for multi-parcel totals;
- a handling fee below or at a configurable merchandise threshold;
- free shipping above a configurable order merchandise threshold.

It deliberately does not implement carrier APIs, labels, tracking, pickup
points, fulfillment orchestration, or a generic shipping framework. Those
responsibilities belong to Solidus or dedicated provider integrations.

## Compatibility

Ruby 3.2 or newer and Solidus 4.6 or 4.7 are required. The release matrix is
deliberately small and covers the supported boundaries:

| Ruby | Rails | Solidus | Role |
| --- | --- | --- | --- |
| 3.2 | 7.0 | 4.6 | oldest supported boundary |
| 3.4 | 7.2 | 4.6 | current Ruby 3 on the secondary Solidus line |
| 3.4 | 7.2 | 4.7 | minimum Rails line for the primary Solidus line |
| 4.0 | 8.1 | 4.7 | primary current stack |

Solidus `main` is exercised separately as an informational compatibility
signal. Solidus 4.5 and older are not supported.

## Installation before the first RubyGems release

```ruby
gem "solidus_weighted_shipping", github: "futhr/solidus-weighted-shipping", branch: "main"
```

Then bundle and configure a shipping method to use `Spree::Calculator::Shipping::WeightedShipping`.

After `4.0.0` is published, replace the Git dependency with the normal RubyGems
constraint:

```ruby
gem "solidus_weighted_shipping", "~> 4.0"
```

Existing stores may continue loading `spree_postal_service` and persisted
`Spree::Calculator::Shipping::PostalService` records during migration. New code
should use the weighted-shipping names.

## How a quote is calculated

The calculator first checks every item against the configured weight and
dimension limits. An ineligible package is unavailable to Solidus rather than
being assigned a guessed price.

For an eligible package, missing or non-positive item weights use the configured
fallback. The total chargeable weight selects the first matching rate band. A
total above the final band is split into repeated final-band parcels plus one
remainder parcel. Free shipping uses the whole order merchandise total, while
handling is evaluated for each package quoted by Solidus.

## Configuration

New calculators expose one structured rate table and explicitly named policy
preferences:

| Preference | Default | Meaning |
| --- | ---: | --- |
| `rate_table` | `1: 6` … `20: 18` | One `maximum weight: price` band per line |
| `maximum_item_weight` | `18` | Maximum weight of any single item |
| `maximum_item_width` | `60` | Maximum second-longest dimension |
| `maximum_item_length` | `120` | Maximum longest dimension |
| `free_shipping_threshold` | `120` | Free shipping when order merchandise total is strictly greater |
| `handling_threshold` | `50` | Handling fee applies at or below this package merchandise total |
| `handling_fee` | `10` | Handling fee |
| `default_item_weight` | `1` | Weight used for missing/zero/negative item weight |

Values are validated before use. Invalid, empty, duplicated, decreasing,
negative, or non-numeric rate configuration is rejected rather than producing
arbitrary checkout behavior.

Weights and dimensions use the host store's configured product units without
performing hidden conversion. Prices and thresholds are decimal amounts in the
order currency; they are not integer minor units. Do not mix units within one
calculator configuration.

Persisted legacy preferences remain readable until they are migrated. Preview
the deterministic conversion with
`DRY_RUN=1 bin/rake solidus_weighted_shipping:preferences:migrate`, then run the
same task without `DRY_RUN` to persist the canonical table, preference names,
and calculator type.

## Behavior carried forward from the legacy extension

The rewrite preserves the strict free-shipping boundary
(`total > free_shipping_threshold`) and repeated maximum-band pricing. Weight,
dimensions, and handling now use the actual Solidus package contents, fixing
the old whole-order/package ambiguity.

See [`docs/migration.md`](docs/migration.md) for the behavioral mapping.

## Development

The repository follows current `solidus_dev_support` conventions.

```sh
bundle install
bin/sandbox
bin/rake
bundle exec rake quality:coverage
bundle exec rake quality:lint
bundle exec rake quality:mutation
```

The pure rating policy is framework-light and exhaustively boundary-tested;
the Solidus adapter is intentionally thin. Browser specs generate the eight
release-evidence screenshots under `tmp/screenshots/`.

## Documentation

- [Architecture and non-goals](docs/architecture.md)
- [Migration from `spree_postal_service`](docs/migration.md)
- [Testing and supported matrix](docs/testing.md)
- [Security and reliability](docs/security.md)
- [Troubleshooting](docs/troubleshooting.md)
- [Release and final-audit procedure](docs/release.md)

## License

BSD 3-Clause. See [LICENSE.md](LICENSE.md).
