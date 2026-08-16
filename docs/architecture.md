# Architecture

Solidus Weighted Shipping owns one missing commerce policy: deterministic,
merchant-configured shipping tariffs based on package weight and item
eligibility. Solidus continues to own shipping methods, zones, stock packages,
estimation, selected rates, shipments, and order state.

## Runtime flow

```text
Spree::Stock::Estimator
  -> Spree::Calculator::Shipping::WeightedShipping
     -> PackageInput (normalized package and order values)
        -> Constraints (item eligibility)
        -> RateTable (validated bands and overflow parcels)
        -> Calculator (free-shipping and handling policy)
           -> Quote (rated, free, unavailable, or empty)
```

The class under `Spree::Calculator` is the required Solidus adapter. All policy
objects live under `SolidusWeightedShipping` and run without Rails when loaded
through `solidus_weighted_shipping/domain`.

## Scope of each value

| Value or rule | Scope | Reason |
| --- | --- | --- |
| item weight and dimensions | quoted package | current Solidus rates packages independently |
| chargeable total weight | quoted package | unrelated order items must not affect eligibility/rate |
| handling threshold and fee | quoted package | preserves calculator-per-package behavior explicitly |
| free-shipping threshold | whole order merchandise total | preserves the historical merchant policy |
| currency | order/package currency | calculator amounts are decimal currency units |

Free shipping remains strictly `order total > threshold`. Handling remains
inclusive at `package total <= threshold`.

## Domain objects

`RateTable` parses a maximum of 1,000 `maximum weight: price` bands, requires
strictly increasing positive thresholds and non-negative prices, and freezes
the canonical bands. Totals above the last band are decomposed into repeated
maximum-weight parcels plus one remainder.

`Constraints` validates positive item/dimension limits and fallback weight.
For every item it sorts the three dimensions, largest first, so orientation
cannot change eligibility. Missing dimensions are zero. A missing, zero, or
negative historical item weight uses the configured positive fallback.

`PackageInput` copies and freezes explicit item values. Names include
`_in_currency_units` and `_in_store_units` to prevent hidden unit assumptions.
It rejects negative prices/dimensions, malformed quantities, and invalid
currency codes.

`Calculator` returns an immutable `Quote`; it does not mutate its input. A
quote has exactly one state: rated, free, unavailable, or empty. Invalid
configuration raises `ConfigurationError`; invalid runtime input raises
`InputError`.

## Solidus adapter

The adapter converts only `Spree::Stock::Package#contents`, using the package's
order only for the explicitly order-scoped free-shipping total. `available?`
returns false and `compute_package` returns nil for invalid configuration or
input, allowing Solidus to omit the method safely. Model validation reports the
underlying configuration message to an administrator.

Parsed policy is memoized by an immutable signature of effective preferences.
Canonical preference writers invalidate legacy keys, and any changed
preference produces a new signature; rating never persists that cache.

## Compatibility boundary

`require "spree_postal_service"` aliases the legacy namespace, and
`Spree::Calculator::Shipping::PostalService` subclasses the canonical
calculator so existing STI records can load. Only `WeightedShipping` is
registered for new methods. The migration task converts old keys and STI types
transactionally; compatibility is a migration bridge, not a second runtime
mode.

## Negative architecture

This extension intentionally has no carrier API, account catalogue, label,
tracking, pickup-point, WMS, fulfillment workflow, generic rules engine,
generic parcelization framework, storefront, or replacement shipment model.
Logical parcel chunks used to calculate price never create persisted Solidus
shipments. Rating performs no network request or database write.
