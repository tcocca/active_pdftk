# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "pdftk_forms/version"

Gem::Specification.new do |s|
  s.name        = "pdftk_forms"
  s.version     = PdftkForms::VERSION
  s.platform    = Gem::Platform::RUBY
  s.authors     = ["Tom Cocca"]
  s.email       = ["tom.cocca@gmail.com"]
  s.homepage    = "http://github.com/tcocca/pdftk_forms"
  s.summary     = "Fill out PDF forms with pdftk."
  s.description = "Fill out editable PDF forms with pdftk (http://www.accesspdf.com/pdftk/)."

  s.rubyforge_project = "pdftk_forms"

  s.add_dependency "builder", '>= 2.1.2'
  s.add_development_dependency "rspec", "~> 2.6.0"
  s.add_development_dependency "rake", ">= 0.8.7"
  s.add_development_dependency "yard"

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]
end
