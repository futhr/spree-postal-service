# Migrating to Solidus Weighted Shipping

The repository, gem, namespace, and primary calculator are now aligned around
Solidus Weighted Shipping. Historical branches and tags remain unchanged.

The repository rename is from `futhr/spree-postal-service` to
`futhr/solidus-weighted-shipping`. Preserve the old GitHub redirect and never
create a different repository at the historical path.

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

## Deployment sequence

1. Back up the database and record every affected calculator ID.
2. Deploy `solidus_weighted_shipping` while leaving the compatibility require
   and STI shim enabled.
3. Run the dry-run task and correct every reported legacy configuration.
4. Run the write task once. It is deterministic and skips already-canonical
   calculators on subsequent runs.
5. Exercise shipping estimation for eligible, oversized, free-shipping, and
   multi-package orders in the target store.
6. Remove the old `spree_postal_service` Gemfile entry and any explicit legacy
   require after the application loads the new gem successfully.

The write task is intentionally one-way: it replaces legacy keys and changes
the STI type to `Spree::Calculator::Shipping::WeightedShipping`. A downgrade to
code that knows only the old class therefore requires restoring the database
backup taken before step 4. There is no permanent `legacy_mode`.

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

## Post-migration verification

For each migrated shipping method, confirm in Solidus admin that:

- the Base Calculator is `Weighted Shipping`;
- the structured rate table contains the expected number of bands;
- the maximum item and dimension values use the store's existing units;
- equality at the free-shipping threshold is still charged;
- equality at the handling threshold still includes handling;
- orders split into multiple packages receive one quote per package.
