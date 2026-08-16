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
