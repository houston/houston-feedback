$:.push File.expand_path("../lib", __FILE__)

# Maintain your gem's version:
require "houston/feedback/version"

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = "houston-feedback"
  s.version     = Houston::Feedback::VERSION
  s.authors     = ["Bob Lail"]
  s.email       = ["bob.lailfamily@gmail.com"]
  s.homepage    = "https://github.com/concordia-publishing-house/houston-alerts"
  s.summary     = "A module for Houston for collecting customer feedback."
  s.description = "A module for Houston for collecting customer feedback."

  s.files = Dir["{app,config,db,lib}/**/*", "MIT-LICENSE", "Rakefile", "README.md"]
  s.test_files = Dir["test/**/*"]

  s.add_dependency "rails"
end
