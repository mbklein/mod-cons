# -*- encoding: utf-8 -*-
lib = File.expand_path('../lib/', __FILE__)
$:.unshift lib unless $:.include?(lib)
  
Gem::Specification.new do |s|
  s.name        = "mod-cons"
  s.version     = "0.1.1"
  s.platform    = Gem::Platform::RUBY
  s.authors     = ["Michael Klein"]
  s.email       = ["mbklein@gmail.com"]
  s.summary     = "Modular Configuration"
  s.description = "Self-declaring, self-aware, modular configuration for Ruby apps"
  s.homepage    = "https://github.com/mbklein/mod-cons"
 
  s.required_rubygems_version = ">= 1.3.6"
  
  # Runtime dependencies
  
  # Bundler will install these gems too if you've checked out dor-services source from git and run 'bundle install'
  # It will not add these as dependencies if you require dor-services for other projects
  s.add_development_dependency 'bundler'
  s.add_development_dependency "rake", ">=0.8.7"
  s.add_development_dependency "rcov"
  s.add_development_dependency "rdoc"
  s.add_development_dependency "rspec"
  s.add_development_dependency "yard"
 
  s.files        = Dir.glob("lib/**/*")
  s.require_path = 'lib'
end