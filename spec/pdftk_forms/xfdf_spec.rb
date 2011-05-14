require 'spec_helper'

describe PdftkForms::Xfdf do
  
  context "generate xfdf" do
    before do
      @xfdf = PdftkForms::Xfdf.new(:test => "one", :user => "tom")
    end
    # Similar ruby issue, I got in the Call specs, hash are not ordered with ruby 1.8.7
    it { @xfdf.to_s.split('').sort.should == valid_xfdf.split('').sort }
  end
  
end
