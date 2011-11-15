require File.expand_path('../../lib/active_pdftk', __FILE__)

require 'rspec'

Dir[File.expand_path(File.join(File.dirname(__FILE__),'support','**','*.rb'))].each {|f| require f}

RSpec.configure do |config|
  config.before(:each) do
    if ENV['embeded_pdftk'] == "true"
      ActivePdftk::Call.stub(:locate_pdftk).and_return(File.dirname(__FILE__) + '/support/pdftk')
    end
  end

  config.filter_run :focus => true
  config.run_all_when_everything_filtered = true
end