# Changelog

## 4.0.0.pre - unreleased

- Rebuild the extension for modern Solidus while preserving repository history and historical tags.
- Align the gem, namespace, and primary calculator with the renamed Solidus Weighted Shipping project.
- Replace parallel legacy weight/price strings with a validated structured rate table and migration task.
- Move rating logic into a small framework-light BigDecimal domain layer.
- Adopt `Spree::ShippingCalculator#compute_package` and `Spree::Stock::Package#contents`.
- Preserve historical preference names and documented pricing boundaries.
- Validate malformed rate tables and parcel constraints.
- Replace legacy Travis/Guard/FactoryGirl-era development tooling with `solidus_dev_support` and GitHub Actions.

Historical release information remains available through the existing tags and `master` branch.
