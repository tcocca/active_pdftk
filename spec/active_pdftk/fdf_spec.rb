require 'spec_helper'

describe ActivePdftk::Fdf do
  context "multiple fields" do
    before do
      @fdf = ActivePdftk::Fdf.new :field1 => 'fieldvalue1', :other_field => 'some other value'
      @fdf_text = @fdf.to_s
    end
    
    it { @fdf_text.should_not be_nil }
    it { @fdf_text.should match(%r{<</T\(field1\)/V\(fieldvalue1\)>>}) }
    it { @fdf_text.should match(%r{<</T\(other_field\)/V\(some other value\)>>}) }
    it "should return the specified path when saving the file" do
      res = @fdf.save_to(path_to_pdf('fdf.txt'))
      res.should == path_to_pdf('fdf.txt')
      res.should be_a(String)
      File.unlink(path_to_pdf('fdf.txt')).should == 1
    end
  end
  
  context "quoting fields" do
    before do
      @fdf = ActivePdftk::Fdf.new :field1 => 'field(va)lue1'
      @fdf_text = @fdf.to_s
    end
    
    it { @fdf_text.should_not be_nil }
    it { @fdf_text.should match(%r{<</T\(field1\)/V\(field\\\(va\\\)lue1\)>>}) }
  end
  
  context "multi-value fields" do
    before do
      @fdf = ActivePdftk::Fdf.new :field1 => %w(one two)
      @fdf_text = @fdf.to_s
    end
    
    it { @fdf_text.should_not be_nil }
    it { @fdf_text.should match(%r{<</T\(field1\)/V\[\(one\)\(two\)\]>>}) }
  end
  
end
