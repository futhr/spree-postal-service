# Migrating to Solidus Weighted Shipping

The repository, gem, namespace, and primary calculator are now aligned around
Solidus Weighted Shipping. Historical branches and tags remain unchanged.

## Dependency and calculator names

Change the dependency and require path:

```ruby
gem "solidus_weighted_shipping", github: "futhr/solidus-weighted-shipping", branch: "main"
```

New shipping methods use
`Spree::Calculator::Shipping::WeightedShipping`. During migration, the root
`spree_postal_service` require aliases the old Ruby namespace and
`Spree::Calculator::Shipping::PostalService` remains loadable for persisted STI
records. Neither legacy name is registered for new shipping methods.

## Preference mapping

The canonical rate table replaces two position-dependent whitespace strings
with one band per line:

```text
1: 6
2: 9
5: 12
10: 15
20: 18
```

The migration maps preferences as follows:

| Historical | Canonical |
| --- | --- |
| `weight_table` + `price_table` | `rate_table` |
| `max_item_weight` | `maximum_item_weight` |
| `max_item_width` | `maximum_item_width` |
| `max_item_length` | `maximum_item_length` |
| `max_price` | `free_shipping_threshold` |
| `handling_max` | `handling_threshold` |
| `handling_fee` | `handling_fee` |
| `default_weight` | `default_item_weight` |

Historical keys are read directly until conversion, so deployment does not
require a synchronized maintenance window. A canonical admin edit clears its
corresponding historical key immediately.

Preview every affected calculator without writing:

```sh
DRY_RUN=1 bin/rake solidus_weighted_shipping:preferences:migrate
```

Then persist the canonical preferences and calculator STI type:

```sh
bin/rake solidus_weighted_shipping:preferences:migrate
```

The task validates the complete converted policy before saving. Invalid legacy
tables are reported by calculator ID and are left unchanged. Back up the
database according to the store's normal deployment procedure before running
any data migration.

## Preserved behavior

- Order merchandise total must be strictly greater than
  `free_shipping_threshold`; equality is not free.
- Handling applies per quoted package when package merchandise total is less
  than or equal to `handling_threshold`.
- Missing, zero, or negative historical item weight uses
  `default_item_weight`.
- The longest dimension is checked against `maximum_item_length`; the
  second-longest is checked against `maximum_item_width`, independent of item
  orientation.
- Totals above the final weight band are charged as repeated maximum-band
  parcels plus the remaining band.

## Intentional corrections

- Item weight, dimensions, and handling totals are package-scoped through
  `Spree::Stock::Package#contents`; free shipping alone remains order-scoped.
- Monetary and physical comparisons use exact decimal values rather than
  binary floats.
- Invalid configuration disables the calculator and appears on model
  validation instead of producing an arbitrary checkout result.
- Preview and availability checks return or consume immutable quote values and
  do not mutate orders, packages, variants, or preferences.
