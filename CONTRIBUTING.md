# Contributing

Changes should keep the extension narrow: a deterministic shipping-rate policy plus the thinnest possible Solidus adapter.

Before submitting changes:

```sh
bundle install
bin/sandbox
bundle exec rake quality:coverage
bundle exec rake quality:lint
bundle exec rake quality:mutation
```

Tests should cover exact boundaries and failure behavior. Do not add carrier APIs, fulfillment, labels, tracking, or generic framework abstractions to this gem.

Browser specs write admin and customer-flow evidence to `tmp/screenshots`.

Use the same environment variables as CI when reproducing a compatibility row:

```sh
RAILS_VERSION=7.0 SOLIDUS_BRANCH=v4.6 bundle exec rake extension:specs
RAILS_VERSION=7.2 SOLIDUS_BRANCH=v4.7 bundle exec rake extension:specs
RAILS_VERSION=8.1 SOLIDUS_BRANCH=v4.7 bundle exec rake extension:specs
```

Regenerate the dummy application after changing Rails or Solidus lines:

```sh
RAILS_VERSION=7.2 SOLIDUS_BRANCH=v4.7 bin/rake clobber extension:test_app
```

Commit one coherent behavior or verification change at a time using
Conventional Commit subjects. Do not commit the generated dummy application,
coverage output, packaged gems, or screenshots.
