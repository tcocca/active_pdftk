require 'rubygems'

begin
  require 'bundler'
  Bundler::GemHelper.install_tasks
rescue LoadError
  task(:build){abort "`gem install bundler` to build gem"}
  task(:install){abort "`gem install bundler` to install gem"}
  task(:release){abort "`gem install bundler` to release gem"}
end

begin
  require 'rspec/core/rake_task'
  RSpec::Core::RakeTask.new
rescue LoadError
  task(:spec){abort "`gem install rspec` to run specs"}
end

task :test => :spec
task :default => :spec

begin
  require 'yard'
  YARD::Rake::YardocTask.new do |t|
    t.options << "--files" << "CHANGELOG.rdoc,LICENSE"
  end
rescue LoadError
  task(:yardoc){abort "`gem install yard` to generate documentation"}
end
