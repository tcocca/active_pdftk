require 'spec_helper'

describe PdftkForms::Xfdf do
  
  context "generate xfdf" do
    before do
      @xfdf = PdftkForms::Xfdf.new(:test => "one", :user => "tom")
    end
    
    it { @xfdf.to_s.should == valid_xfdf }
  end
  
end
