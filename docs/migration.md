# Migration from the legacy Spree extension

The `main` branch is a rewrite built on the original repository history. Existing tags and the historical `master` branch remain unchanged.

## Preserved preferences

All historical calculator preference names are retained so existing configuration can be mapped directly:

`weight_table`, `price_table`, `max_item_weight`, `max_item_width`, `max_item_length`, `max_price`, `handling_max`, `handling_fee`, and `default_weight`.

Whitespace-separated weight and price tables remain accepted at the public preference boundary, but are parsed once into validated `BigDecimal` values internally.

## Intentional behavior

Preserved:

- `total > max_price` means free shipping; equality is not free;
- handling fee applies when merchandise value is less than or equal to `handling_max`;
- missing/non-positive weight uses `default_weight`;
- longest dimension is checked against `max_item_length`;
- second-longest dimension is checked against `max_item_width`;
- totals above the final weight band are charged as repeated maximum-band parcels plus the remaining band.

Changed:

- item weight/dimension rating is package-scoped using `Spree::Stock::Package#contents`, matching current Solidus shipping estimation;
- monetary and physical threshold arithmetic uses exact decimal values instead of Float;
- invalid rate tables fail validation instead of being interpreted implicitly;
- the misleading legacy helper name `item_within_bounds?` is gone.

## Release note

The working version is `3.0.0.pre` until final naming, compatibility, RubyGems ownership, and release audit are complete. Do not publish from `main` before that audit.
