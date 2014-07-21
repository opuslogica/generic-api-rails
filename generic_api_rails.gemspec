$:.push File.expand_path("../lib", __FILE__)

# Maintain your gem's version:
require "generic_api_rails/version"

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = "generic_api_rails"
  s.version     = GenericApiRails::VERSION
  s.authors     = ["Daniel Staudigel"]
  s.email       = ["dstaudigel@opuslogica.com"]
  s.homepage    = "http://opuslogica.com/"
  s.summary     = "Provides a simple API interface for dealing with the database."
  s.description = "Simple API server with easy configuratino for authentication mechanism & automagic RESTful api."

  s.files = Dir["{app,config,db,lib}/**/*", "MIT-LICENSE", "Rakefile", "README.rdoc"]
  s.test_files = Dir["test/**/*"]

  s.add_dependency "rails", "~> 4"

  s.add_runtime_dependency "koala"

  s.add_development_dependency "sqlite3"
end
