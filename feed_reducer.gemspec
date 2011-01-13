# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "feed_yamlizer/version"

Gem::Specification.new do |s|
  s.name        = "feed_yamlizer"
  s.version     = Vmail::VERSION
  s.platform    = Gem::Platform::RUBY
  s.authors     = ["Daniel Choi"]
  s.email       = ["dhchoi@gmail.com"]
  s.homepage    = "TODO"
  s.summary     = %q{A feed parser and converter}
  s.description = %q{Converts feeds to YAML and extracts plain text content}

  s.rubyforge_project = "feed_yamlizer"

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]
  s.add_dependency 'nokogiri'
end
