# coding: utf-8
lib = File.expand_path('../lib/', __FILE__)
$:.unshift lib unless $:.include?(lib)

require 'spree_postal_service/version'

Gem::Specification.new do |s|
  s.platform     = Gem::Platform::RUBY
  s.name         = 'spree_postal_service'
  s.version      = SpreePostalService.version
  s.summary      = 'Calculate weight based charges for a Spree order'
  s.description  = s.summary
  s.required_ruby_version = '>= 1.8.7'

  s.authors      = ['Torsten Rüger', 'Tobias Bohwalli']
  s.email        = 'hi@futhr.io'
  s.homepage     = 'https://github.com/futhr/spree-postal-service'
  s.license      = %q{BSD-3}

  s.files        = `git ls-files`.split("\n")
  s.test_files   = `git ls-files -- spec/*`.split("\n")
  s.require_path = 'lib'
  s.requirements << 'none'

  s.has_rdoc = false

  s.add_dependency 'spree_core', '~> 1.3.0'

  s.add_development_dependency 'rspec', '~> 2.7.0'
  s.add_development_dependency 'rspec-rails', '~> 2.7'
  s.add_development_dependency 'factory_girl', '~> 2.6.3'
  s.add_development_dependency 'sqlite3'
  s.add_development_dependency 'simplecov'
  s.add_development_dependency 'i18n-spec'
  s.add_development_dependency 'ffaker'
  s.add_development_dependency 'guard-rspec'
  s.add_development_dependency 'pry-rails'
end
