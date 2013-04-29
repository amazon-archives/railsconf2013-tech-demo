$:.push File.expand_path("../lib", __FILE__)

# Maintain your gem's version:
require "seahorse/version"

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = "seahorse"
  s.version     = Seahorse::VERSION
  s.authors     = ["Loren Segal", "Trevor Rowe"]
  s.email       = ["amazon@amazon.com"]
  s.homepage    = "http://github.com/awslabs/seahorse"
  s.summary     = "Seahorse is a way to describe web services"
  s.description = "Easy web service descriptions"
  s.files = Dir["{app,config,db,lib}/**/*", "LICENSE", "Rakefile", "README.md"]
  s.test_files = Dir["test/**/*"]
  s.add_dependency 'activesupport'
  s.add_dependency 'oj'
end
