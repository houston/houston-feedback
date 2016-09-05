$:.push File.expand_path("../lib", __FILE__)

# Maintain your gem's version:
require "houston/feedback/version"

# Describe your gem and declare its dependencies:
Gem::Specification.new do |spec|
  spec.name        = "houston-feedback"
  spec.version     = Houston::Feedback::VERSION
  spec.authors     = ["Bob Lail"]
  spec.email       = ["bob.lailfamily@gmail.com"]

  spec.summary     = "A module for Houston for collecting customer feedback."
  spec.description = "A module for Houston for collecting customer feedback."
  spec.homepage    = "https://github.com/concordia-publishing-house/houston-feedback"

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.require_paths = ["lib"]
  spec.test_files = Dir["test/**/*"]

  spec.add_dependency "houston-core", ">= 0.8.0.pre"
  spec.add_dependency "pg_search"
  spec.add_dependency "activerecord-import"
  spec.add_dependency "pluck_map"

  spec.add_development_dependency "bundler", "~> 1.11.2"
  spec.add_development_dependency "rake", "~> 11.2"
  spec.add_development_dependency "factory_girl_rails"
end
