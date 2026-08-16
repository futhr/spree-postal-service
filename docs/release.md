# Release and final audit

## Final decision

### Decision

Maintain as a narrowly scoped Solidus extension.

### Final repository name

`futhr/solidus-weighted-shipping`

### Gem namespace

`solidus_weighted_shipping`, with `SolidusWeightedShipping` and
`Spree::Calculator::Shipping::WeightedShipping` as the canonical runtime names.
The old require, namespace alias, and calculator subclass exist only for
migration.

### Evidence

- The policy is not duplicated by Solidus core calculators.
- The pure domain is separated from the Solidus adapter and has no external
  effects.
- Solidus 4.6/4.7, Rails 7.0/7.2/8.1, and Ruby 3.2/3.4/4.0 combinations pass.
- Unit, property, mutation, integration, system, packaging, lint, coverage, and
  dependency gates exist.
- A clean `solidus_dev_support` dummy app rebuild succeeds.
- Eight admin/customer screenshots are asserted and inspected.

### Migration

Use `docs/migration.md`. The deterministic task has a dry-run mode, validates
the complete converted policy, and changes preferences/STI type atomically.

### Known limitations

No carrier APIs, unit conversion, multi-currency rate table, labels, tracking,
pickup points, storefront, generic rules engine, or shipment creation. Handling
is per package; free shipping is based on whole-order merchandise total.

## External publication audit

On 16 August 2026, the public RubyGems API reported legacy
`spree_postal_service` 2.4.0 with historical downloads, while
`solidus_weighted_shipping` returned not found. That suggests the new name was
available at that instant but is not a reservation; recheck immediately before
publishing. RubyGems owner access cannot be proven without maintainer
credentials and remains a mandatory release check.

The source tree and package metadata assume the agreed renamed repository.
During the same audit, the public GitHub API still exposed the legacy path and
did not resolve the final path. Before release, confirm the rename/redirect has
propagated, update the local `origin`, and never recreate the historical path
while relying on its redirect.

## Release checklist

1. Refresh Solidus security support, Rails/Ruby compatibility, Actions
   versions, and ecosystem-overlap findings.
2. Verify the final GitHub path, default `main` branch, repository description,
   topics, old-path redirect, issues, releases, and preserved history.
3. Authenticate to RubyGems, verify owners/MFA, recheck both gem names and
   reverse dependencies, and decide whether authorized owners will publish a
   final old-gem successor/deprecation notice.
4. Remove every expired advisory exception and run:

   ```sh
   bin/sandbox
   bundle exec rake quality:coverage
   bundle exec rake quality:lint
   MUTANT_JOBS=4 bundle exec rake quality:mutation
   bundle exec bundle-audit check --update
   actionlint .github/workflows/*.yml
   ```

5. Run every supported CI matrix row from a clean dependency resolution and
   assess the non-blocking Solidus `main` result.
6. Inspect all eight screenshots for layout, generated-only data, and coherent
   prices; confirm the customer preview controller is absent from the package.
7. Build and inspect the gem:

   ```sh
   mkdir -p pkg
   gem build solidus_weighted_shipping.gemspec \
     --output pkg/solidus_weighted_shipping.gem
   gem specification pkg/solidus_weighted_shipping.gem
   ```

8. Install the built artifact into a temporary gem home and load
   `solidus_weighted_shipping/domain` without the repository on `$LOAD_PATH`.
9. Change `4.0.0.pre` to the approved stable version, update this changelog,
   commit with a Conventional Commit subject, and rerun the complete gates.
10. Create an annotated Git tag such as `v4.0.0` on the exact release commit,
    push `main` and the tag, publish with MFA, and verify the downloaded gem
    checksum/metadata from RubyGems.

Do not tag or publish from a dirty tree, do not move a published release tag,
and do not release while repository routing or RubyGems ownership is uncertain.
