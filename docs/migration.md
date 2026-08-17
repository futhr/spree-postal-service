# Migrating to Solidus Weighted Shipping

The repository, gem, namespace, and primary calculator are now aligned around
Solidus Weighted Shipping. Historical branches and tags remain unchanged.

This guide is for stores upgrading from `spree_postal_service`. New
installations can start with the canonical dependency and calculator names and
do not need to run the preference migration.

The repository is now `futhr/solidus-weighted-shipping`. Preserve the GitHub
redirect from the historical repository path.

## Dependency and calculator names

Change the dependency and require path:

```ruby
gem "solidus_weighted_shipping", github: "futhr/solidus-weighted-shipping", branch: "main"
```

New shipping methods use
`Spree::Calculator::Shipping::WeightedShipping`. The new gem deliberately does
not define `SpreePostalService`, provide `require "spree_postal_service"`, or
load `Spree::Calculator::Shipping::PostalService`. The migration task treats
the old calculator name strictly as persisted data.

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

The migration task recognizes historical keys and converts them into canonical
preferences. A canonical admin edit clears any corresponding historical key.

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
2. Stop web and worker processes that could load a legacy calculator row.
3. Replace the old dependency with `solidus_weighted_shipping`, then boot only
   the release process used to run the migration task.
4. Run the dry-run task and correct every reported legacy configuration.
5. Run the write task once. It is deterministic and skips already-canonical
   calculators on subsequent runs.
6. Start application processes and exercise shipping estimation for eligible,
   oversized, free-shipping, and
   multi-package orders in the target store.

The task selects and locks legacy rows without instantiating their STI class,
temporarily assigns the canonical type inside a transaction, validates the
converted policy, and commits only a successful write. Dry runs and failures
roll back the type and preferences together. This cutover is intentionally an
explicit maintenance boundary rather than a permanent compatibility layer.

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
