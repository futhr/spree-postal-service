# Contributing

Thanks for helping improve Solidus Weighted Shipping. The project stays
deliberately narrow: it provides a deterministic shipping-rate policy and the
thinnest practical Solidus adapter. Carrier APIs, fulfillment, labels,
tracking, and generic rules-engine abstractions belong elsewhere.

## Set up the project

```sh
bundle install
bin/sandbox
bin/rake
```

`bin/sandbox` creates a disposable Solidus dummy application under
`spec/dummy`. It is safe to rebuild and must not be committed.

## Verify a change

Run the focused spec while developing, then run the complete gates before
submitting the change:

```sh
bin/rake
bundle exec rake quality:coverage
bundle exec rake quality:lint
bundle exec rake quality:mutation
```

Tests should cover exact boundaries and failure behavior. Changes to pricing or
eligibility need mutation evidence as well as example-based tests. Browser specs
write admin and customer-flow evidence to `tmp/screenshots`; inspect those images
when the rendered workflow changes.

## Reproduce a compatibility row

Set the Rails and Solidus versions before dependency resolution, then keep those
variables on the dummy-app and test commands. For example:

```sh
RAILS_VERSION=7.0 SOLIDUS_BRANCH=v4.6 bundle install
RAILS_VERSION=7.0 SOLIDUS_BRANCH=v4.6 bin/sandbox
RAILS_VERSION=7.0 SOLIDUS_BRANCH=v4.6 bin/rake extension:specs
```

The supported rows are listed in the
[testing guide](docs/testing.md#supported-matrix). Rebuild the dummy application
whenever either version changes. If Bundler retains a resolution from another
row, use a separate bundle path or remove only that disposable bundle before
resolving again.

## Keep changes reviewable

Update documentation whenever public names, preferences, behavior, support
boundaries, or release steps change. Add an entry under `Unreleased` in
`CHANGELOG.md` for changes users will notice.

Make each commit one coherent behavior, test, documentation, or maintenance
change. Use Conventional Commit subjects such as `feat:`, `fix:`, `test:`,
`docs:`, or `chore:`. Do not commit the generated dummy application, coverage
output, packaged gems, or screenshots.
