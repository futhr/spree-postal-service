# Solidus Weighted Shipping

Weight- and parcel-rule shipping for modern Solidus.

This repository preserves the history of the original Spree extension while `main` carries the current Solidus rewrite. The historical `master` branch and all existing tags remain untouched.

## What it does

`solidus_weighted_shipping` adds one Solidus shipping calculator with:

- configurable weight bands and prices;
- maximum per-item weight;
- longest-side and second-longest-side limits independent of orientation;
- fallback weight for products without a positive weight;
- repeated maximum-band charging for multi-parcel totals;
- a handling fee below or at a configurable merchandise threshold;
- free shipping above a configurable order merchandise threshold.

It deliberately does **not** implement carrier APIs, labels, tracking, pickup points, fulfillment orchestration, or a generic shipping framework. Those responsibilities belong to Solidus or dedicated provider integrations.

## Compatibility

The modernization targets Solidus 4.7 first and Solidus 4.6 while that line remains security-supported. Ruby 3.2 or newer is required.

## Installation

```ruby
gem "solidus_weighted_shipping", github: "futhr/solidus-weighted-shipping", branch: "main"
```

Then bundle and configure a shipping method to use `Spree::Calculator::Shipping::WeightedShipping`.

Existing stores may continue loading `spree_postal_service` and persisted
`Spree::Calculator::Shipping::PostalService` records during migration. New code
should use the weighted-shipping names.

## Configuration

The historical preference names are intentionally retained:

| Preference | Default | Meaning |
| --- | ---: | --- |
| `weight_table` | `1 2 5 10 20` | Strictly increasing weight thresholds |
| `price_table` | `6 9 12 15 18` | Price for each corresponding band |
| `max_item_weight` | `18` | Maximum weight of any single item |
| `max_item_width` | `60` | Maximum second-longest dimension |
| `max_item_length` | `120` | Maximum longest dimension |
| `max_price` | `120` | Free shipping when order merchandise total is strictly greater |
| `handling_max` | `50` | Handling fee applies at or below this package merchandise total |
| `handling_fee` | `10` | Handling fee |
| `default_weight` | `1` | Weight used for missing/zero/negative item weight |

Values are validated before use. Invalid, empty, mismatched, duplicated, decreasing, negative, or non-numeric rate configuration is rejected rather than producing arbitrary checkout behavior.

## Compatibility notes from the legacy implementation

The rewrite intentionally preserves the historical strict free-shipping boundary (`total > max_price`) and repeated maximum-band pricing. Weight and dimension rating now uses the **actual Solidus package contents**, fixing the old whole-order/package ambiguity.

See [`docs/migration.md`](docs/migration.md) for the behavioral mapping.

## Development

The repository follows current `solidus_dev_support` conventions.

```sh
bundle install
bin/sandbox
bundle exec rake
bundle exec rubocop
```

The pure rating policy is framework-light and exhaustively boundary-tested; the Solidus adapter is intentionally thin.

## License

BSD 3-Clause. See [LICENSE.md](LICENSE.md).
