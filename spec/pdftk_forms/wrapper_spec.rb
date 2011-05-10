require 'spec_helper'

describe PdftkForms::Wrapper do

  # The test suite should work on any system, which is quite tricky,
  # here we try to locate the pdftk library, this should work on any unix system.
  # Maybe for broader support it is better to ask user for the path.
  pdftk_path = %x{locate pdftk | grep "/bin/pdftk"}.strip
  pdftk_path = nil if pdftk_path.empty?

  context "new" do
    it "should set the default path" do
      @pdftk = PdftkForms::Wrapper.new
      @pdftk.path.should == "pdftk"
    end

    it "should allow for custom paths" do
      # Elmatou : on my system the binary is located at /usr/bin/pdftk and the previous test failed.
      @pdftk = PdftkForms::Wrapper.new(pdftk_path || '/usr/local/bin/pdftk')
      @pdftk.path.should == pdftk_path || '/usr/local/bin/pdftk'
    end

    it "should raise PdftkForms::MissingLibrary if pdftk is not found" do
      expect{ PdftkForms::Wrapper.new('/path/to/nothing') }.to raise_error(PdftkForms::MissingLibrary)
    end
  end

  context "fields" do
    before do
      @pdftk = PdftkForms::Wrapper.new
      @fields = @pdftk.fields(path_to_pdf('fields'))
    end

    it "should get the total number of fields" do
      @fields.size.should == 8
    end

    it "should return an array of PdftkForms::Field objects" do
      @fields.each do |field|
        field.should be_kind_of(PdftkForms::Field)
      end
    end

    it "should set the field data" do
      @fields[0].name.should == "text_not_required"
      @fields[0].value.should == nil
      @fields[0].type.should == "Text"
      @fields[0].flags.should == "0"
      @fields[0].alt_name.should == nil
      @fields[0].options.should == nil
      @fields[0].field_type.should == "text_field"

      @fields[1].name.should == "combo_box"
      @fields[1].value.should == nil
      @fields[1].type.should == "Choice"
      @fields[1].flags.should == "131072"
      @fields[1].alt_name.should == nil
      @fields[1].options.should == ["Jason", "Tom"]
      @fields[1].field_type.should == "select"

      @fields[2].name.should == "text_required"
      @fields[2].value.should == nil
      @fields[2].type.should == "Text"
      @fields[2].flags.should == "2"
      @fields[2].alt_name.should == nil
      @fields[2].options.should == nil
      @fields[2].field_type.should == "text_field"

      @fields[3].name.should == "check_box"
      @fields[3].value.should == nil
      @fields[3].type.should == "Button"
      @fields[3].flags.should == "0"
      @fields[3].alt_name.should == nil
      @fields[3].options.should == ["Off", "Yes"]
      @fields[3].field_type.should == "check_box"

      @fields[4].name.should == "radio_button"
      @fields[4].value.should == nil
      @fields[4].type.should == "Button"
      @fields[4].flags.should == "49152"
      @fields[4].alt_name.should == nil
      @fields[4].options.should == ["No", "Off", "Yes"]
      @fields[4].field_type.should == "radio_button"

      @fields[5].name.should == "list_box"
      @fields[5].value.should == "sam"
      @fields[5].type.should == "Choice"
      @fields[5].flags.should == "0"
      @fields[5].alt_name.should == nil
      @fields[5].options.should == ["dave", "sam"]
      @fields[5].field_type.should == "select"

      @fields[6].name.should == "button"
      @fields[6].value.should == nil
      @fields[6].type.should == "Button"
      @fields[6].flags.should == "65536"
      @fields[6].alt_name.should == nil
      @fields[6].options.should == nil
      @fields[6].field_type.should == "push_button"

      @fields[7].name.should == "text_area"
      @fields[7].value.should == nil
      @fields[7].type.should == "Text"
      @fields[7].flags.should == "4096"
      @fields[7].alt_name.should == nil
      @fields[7].options.should == nil
      @fields[7].field_type.should == "text_area"
    end
  end

  def path_to_pdf(filename)
    File.join File.dirname(__FILE__), '../', 'test_pdfs', "#{filename}.pdf"
  end

end

