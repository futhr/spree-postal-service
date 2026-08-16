# Contributing

Changes should keep the extension narrow: a deterministic shipping-rate policy plus the thinnest possible Solidus adapter.

Before submitting changes:

```sh
bundle install
bin/sandbox
bundle exec rake
bundle exec rubocop
```

Tests should cover exact boundaries and failure behavior. Do not add carrier APIs, fulfillment, labels, tracking, or generic framework abstractions to this gem.
