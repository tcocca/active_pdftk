require 'spec_helper'

describe PdftkForms::Xfdf do
  
  context "generate xfdf" do
    before do
      @xfdf = PdftkForms::Xfdf.new(:test => "one", :user => "tom")
    end
    # Similar ruby issue, I got in the Call specs, hash are not ordered with ruby 1.8.7
    it { @xfdf.to_s.split('').sort.should == valid_xfdf.split('').sort }
    it "should return the specified path when saving the file" do
      res = @xfdf.save_to(path_to_pdf('xfdf.txt'))
      res.should == path_to_pdf('xfdf.txt')
      res.should be_a(String)
      File.unlink(path_to_pdf('xfdf.txt')).should == 1
    end
  end
  
end
