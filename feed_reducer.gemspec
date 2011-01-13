# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "feed_reducer/version"

Gem::Specification.new do |s|
  s.name        = "feed_reducer"
  s.version     = Vmail::VERSION
  s.platform    = Gem::Platform::RUBY
  s.authors     = ["Daniel Choi"]
  s.email       = ["dhchoi@gmail.com"]
  s.homepage    = "http://danielchoi.com/software/feed_reducer.html"
  s.summary     = %q{A Vim news reader}
  s.description = %q{Read your feeds in Vim}

  s.rubyforge_project = "feed_reducer"

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]

  # s.add_dependency 'highline', '>= 1.6.1'
end
