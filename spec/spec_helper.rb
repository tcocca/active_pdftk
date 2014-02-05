require File.expand_path('../../lib/active_pdftk', __FILE__)

require 'rspec'
require 'digest'

puts ActivePdftk::Call.locate_pdftk.inspect

Dir[File.expand_path(File.join(File.dirname(__FILE__),'support','**','*.rb'))].each {|f| require f}

RSpec.configure do |config|
  config.filter_run :focus => true
  config.run_all_when_everything_filtered = true
end
