# -*- encoding: utf-8 -*-
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
# $:.push File.expand_path("../lib", __FILE__)

# Maintain your gem's version:
require "generic_api_rails/version"

# Describe your gem and declare its dependencies:
Gem::Specification.new do |gem|
  gem.name              = "generic-api-rails"
  gem.version           = GenericApiRails::VERSION
  gem.authors           = ["Daniel Staudigel", "Brian J. Fox", "Khrysle Rae-Dunn"]
  gem.email             = ["dstaudigel@opuslogica.com", "bfox@opuslogica.com", "krae@opuslogica.com"]
  gem.description       = "Simple API server with easy configuratino for authentication mechanism & automagic RESTful api."
  gem.summary           = "Provides a simple API interface for dealing with the database."
  gem.homepage          = "https://github.com/opuslogica/generic-api-rails"
  gem.license           = "AGPLv3"
  gem.files             = `git ls-files`.split($/)
  gem.test_files        = gem.files.grep(%r{^(test|spec|features)/})
  gem.require_paths     = ["lib"]
  gem.add_dependency    "rails", "> 4"
  gem.add_runtime_dependency "koala"
  gem.add_development_dependency "sqlite3"
end
