require 'spec_helper'

describe PdftkForms::Fdf do
  context "multiple fields" do
    before do
      @fdf = PdftkForms::Fdf.new :field1 => 'fieldvalue1', :other_field => 'some other value'
      @fdf_text = @fdf.to_fdf
    end
    
    it { @fdf_text.should_not be_nil }
    it { @fdf_text.should match(%r{<</T\(field1\)/V\(fieldvalue1\)>>}) }
    it { @fdf_text.should match(%r{<</T\(other_field\)/V\(some other value\)>>}) }
  end
  
  context "quoting fields" do
    before do
      @fdf = PdftkForms::Fdf.new :field1 => 'field(va)lue1'
      @fdf_text = @fdf.to_fdf
    end
    
    it { @fdf_text.should_not be_nil }
    it { @fdf_text.should match(%r{<</T\(field1\)/V\(field\\\(va\\\)lue1\)>>}) }
  end
  
  context "multi-value fields" do
    before do
      @fdf = PdftkForms::Fdf.new :field1 => %w(one two)
      @fdf_text = @fdf.to_fdf
    end
    
    it { @fdf_text.should_not be_nil }
    it { @fdf_text.should match(%r{<</T\(field1\)/V\[\(one\)\(two\)\]>>}) }
  end
  
end
