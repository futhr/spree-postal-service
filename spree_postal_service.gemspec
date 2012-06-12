Gem::Specification.new do |s|
  s.platform    = Gem::Platform::RUBY
  s.name        = 'spree_postal_service'
  s.version     = '1.1'
  s.summary     = 'Calculate weight based charges for a spree order'
  s.required_ruby_version = '>= 1.8.7'

  s.author            = 'Torsten Ruger'
  s.email             = 'torsten@villataika.fi'
  s.homepage          = 'https://github.com/dancinglightning/spree-postal-service'

  s.files        = Dir['CHANGELOG', 'README.md', 'LICENSE', 'lib/**/*', 'app/**/*']
  s.require_path = 'lib'
  s.requirements << 'none'

  s.has_rdoc = true

  s.add_dependency('spree_core', '>= 1.1')
end