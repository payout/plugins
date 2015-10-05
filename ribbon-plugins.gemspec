$:.push File.expand_path("../lib", __FILE__)

# Maintain your gem's version:
require "plugins/version"

Gem::Specification.new do |s|
  s.name        = 'plugins'
  s.version     = Plugins::VERSION
  s.homepage    = "http://github.com/payout/plugins"
  s.summary     = "A flexible plugins framework."
  s.description = s.summary
  s.authors     = ["Robert Honer"]
  s.email       = ['robert@payout.com']
  s.files       = Dir['lib/**/*.rb']
  s.license     = 'BSD'

  s.add_development_dependency 'rspec', '~>3.2', '>=3.2.0'
end
