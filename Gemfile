# frozen_string_literal: true

source "https://rubygems.org"
git_source(:github) { |repo| "https://github.com/#{repo}.git" }

solidus_branch = ENV.fetch("SOLIDUS_BRANCH", "v4.7")
gem "solidus", github: "solidusio/solidus", branch: solidus_branch

rails_version = ENV.fetch("RAILS_VERSION", "7.2")
rails_minor = Gem::Version.new(rails_version).segments.first(2).join(".")
gem "rails", "~> #{rails_minor}.0"
gem "sqlite3", (rails_version < "7.2") ? "~> 1.4" : "~> 2.0"
gem "ransack", "~> 4.3.0" if Gem::Version.new(rails_version) < Gem::Version.new("7.2")

gem "csv" if RUBY_VERSION >= "3.4"

gemspec
