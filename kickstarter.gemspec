# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "kickstarter/version"

Gem::Specification.new do |s|
  s.name        = "kickstarter"
  s.version     = Kickstarter::VERSION
  s.authors     = ["John Tajima"]
  s.email       = ["manjiro@gmail.com"]
  s.homepage    = ""
  s.summary     = %q{A simple wrapper for Kickstarter.com}
  s.description = %q{A simple wrapper for kickstarter.com}

  s.rubyforge_project = "kickstarter"

  s.add_dependency "nokogiri"
  s.add_development_dependency "fakeweb"
  
  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]
end
