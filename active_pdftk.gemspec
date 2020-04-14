# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "active_pdftk/version"

Gem::Specification.new do |s|
  s.name        = "active_pdftk"
  s.version     = ActivePdftk::VERSION
  s.platform    = Gem::Platform::RUBY
  s.authors     = ["Tom Cocca"]
  s.email       = ["tom.cocca@gmail.com"]
  s.homepage    = "http://github.com/tcocca/active_pdftk"
  s.summary     = "Fill out PDF forms with pdftk."
  s.description = "Fill out editable PDF forms with pdftk (http://www.accesspdf.com/pdftk/)."

  s.add_dependency 'builder', '>= 2.1.2'
  s.add_development_dependency 'rspec', '~> 2.6.0'
  s.add_development_dependency 'rake', '>= 0.8.7'
  s.add_development_dependency 'yard'
  s.add_development_dependency 'fuubar'

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]
end
