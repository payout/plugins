$:.push File.expand_path("../lib", __FILE__)

# Maintain your gem's version:
require "ribbon/plugins/version"

Gem::Specification.new do |s|
  s.name        = 'ribbon-plugins'
  s.version     = Ribbon::Plugins::VERSION
  s.homepage    = "http://github.com/ribbon/plugins"
  s.summary     = "A flexible plugins framework."
  s.description = s.summary
  s.authors     = ["Robert Honer"]
  s.email       = ['robert@ribbonpayments.com']
  s.files       = Dir['lib/**/*.rb']

  s.add_development_dependency 'rspec'
end