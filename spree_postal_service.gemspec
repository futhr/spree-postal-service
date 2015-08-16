# coding: utf-8
lib = File.expand_path('../lib/', __FILE__)
$LOAD_PATH.unshift lib unless $LOAD_PATH.include?(lib)

require 'spree_postal_service/version'

Gem::Specification.new do |s|
  s.platform     = Gem::Platform::RUBY
  s.name         = 'spree_postal_service'
  s.version      = SpreePostalService.version
  s.summary      = 'Calculate weight based charges for a Spree order'
  s.description  = s.summary

  s.required_ruby_version     = '>= 2.1.0'
  s.required_rubygems_version = '>= 1.8.23'

  s.authors      = ['Torsten Rüger', 'Tobias Bohwalli']
  s.email        = ['torsten@villataika.fi', 'hi@futhr.io']
  s.homepage     = 'https://github.com/futhr/spree-postal-service'
  s.license      = 'BSD-3'

  s.files        = `git ls-files`.split("\n")
  s.test_files   = `git ls-files -- spec/*`.split("\n")
  s.require_path = 'lib'
  s.requirements << 'none'

  s.has_rdoc = false

  s.add_runtime_dependency 'spree_core', '~> 3.1.0.beta'

  s.add_development_dependency 'rspec-rails', '~> 3.3.0'
  s.add_development_dependency 'factory_girl', '>= 4.4'
  s.add_development_dependency 'sqlite3', '~> 1.3.10'
  s.add_development_dependency 'simplecov', '~> 0.10.0'
  s.add_development_dependency 'coveralls', '>= 0.8.1'
  s.add_development_dependency 'i18n-spec', '>= 0.6.0'
  s.add_development_dependency 'ffaker', '>= 1.32.1'
  s.add_development_dependency 'coffee-rails', '~> 4.0.0'
  s.add_development_dependency 'sass-rails', '~> 5.0.0'
  s.add_development_dependency 'pry-rails', '>= 0.3.2'
  s.add_development_dependency 'database_cleaner', '1.4.1'
  s.add_development_dependency 'guard-rspec', '>= 4.2.8'
  s.add_development_dependency 'rubocop', '>= 0.24.1'
end
