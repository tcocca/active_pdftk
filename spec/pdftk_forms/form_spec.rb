require 'spec_helper'

describe PdftkForms::Form do
  context "new" do
    it "should create a PdftkForms::Form object" do
      @form = PdftkForms::Form.new(path_to_pdf('fields.pdf'))
      @form.should be_kind_of(PdftkForms::Form)
      @form.template.should == path_to_pdf('fields.pdf')
    end
  end

  context "Instantiate a Form, " do
    before do
      @form = PdftkForms::Form.new(path_to_pdf('fields.pdf'))
    end

    context "fields" do
      it "should get the total number of fields" do
        @form.fields.size.should == 8
      end

      it "should return an array of PdftkForms::Field objects" do
        @form.fields.each do |field|
          field.should be_kind_of(PdftkForms::Field)
        end
      end

      it "should set the field data" do
        fields = @form.fields
        fields[0].name.should == "text_not_required"
        fields[0].value.should == nil
        fields[0].type.should == "Text"
        fields[0].flags.should == "0"
        fields[0].alt_name.should == nil
        fields[0].options.should == nil
        fields[0].field_type.should == "text_field"

        fields[1].name.should == "combo_box"
        fields[1].value.should == nil
        fields[1].type.should == "Choice"
        fields[1].flags.should == "131072"
        fields[1].alt_name.should == nil
        fields[1].options.should == ["Jason", "Tom"]
        fields[1].field_type.should == "select"

        fields[2].name.should == "text_required"
        fields[2].value.should == nil
        fields[2].type.should == "Text"
        fields[2].flags.should == "2"
        fields[2].alt_name.should == nil
        fields[2].options.should == nil
        fields[2].field_type.should == "text_field"

        fields[3].name.should == "check_box"
        fields[3].value.should == nil
        fields[3].type.should == "Button"
        fields[3].flags.should == "0"
        fields[3].alt_name.should == nil
        fields[3].options.should == ["Off", "Yes"]
        fields[3].field_type.should == "check_box"

        fields[4].name.should == "radio_button"
        fields[4].value.should == nil
        fields[4].type.should == "Button"
        fields[4].flags.should == "49152"
        fields[4].alt_name.should == nil
        fields[4].options.should == ["No", "Off", "Yes"]
        fields[4].field_type.should == "radio_button"

        fields[5].name.should == "list_box"
        fields[5].value.should == "sam"
        fields[5].type.should == "Choice"
        fields[5].flags.should == "0"
        fields[5].alt_name.should == nil
        fields[5].options.should == ["dave", "sam"]
        fields[5].field_type.should == "select"

        fields[6].name.should == "button"
        fields[6].value.should == nil
        fields[6].type.should == "Button"
        fields[6].flags.should == "65536"
        fields[6].alt_name.should == nil
        fields[6].options.should == nil
        fields[6].field_type.should == "push_button"

        fields[7].name.should == "text_area"
        fields[7].value.should == nil
        fields[7].type.should == "Text"
        fields[7].flags.should == "4096"
        fields[7].alt_name.should == nil
        fields[7].options.should == nil
        fields[7].field_type.should == "text_area"
      end
    end

    context "to_h" do
      it "should return the reduced hash" do
        @form.field_mapping_fill!.to_h.should == {"list_box"=>"sam", "text_not_required"=>"text_not_required", "text_area"=>"text_area", "text_required"=>"text_required"}
      end

      it "(true) should return the full hash" do
        @form.to_h(true).should == {"button"=>"", "radio_button"=>"", "check_box"=>"", "list_box"=>"sam", "text_not_required"=>"", "text_area"=>"", "combo_box"=>"", "text_required"=>""}
      end
    end

    context "get" do
      it "should retrieve the field object" do
        @form.get('text_not_required').should == @form.fields[0]
      end

      it "should be nil for a not existing field" do
        @form.get('not_a_field').should be_nil
      end
    end

    context "set" do
      it "should set the value of a given field_name" do
        @form.set('text_not_required', 'but provided')
        @form.fields[0].value.should == 'but provided'
      end

      it "should return false for a not valid field_name" do
        @form.set('not_a_field', 'whatever').should be_false
      end

      it "should return false when calling set on a read_only? field" do
        @form.fields[0].stub!(:read_only?).and_return(true)
        @form.set(@form.fields[0].name, 'test').should be_false
      end
    end

    context "method_missing" do
      it "should allow to access do the getters" do
        @form.text_not_required.should == @form.fields[0]
      end

      it "should allow to access do the setters" do
        @form.text_not_required=('and not provided').should == 'and not provided'
      end

      it " `respond_to?` should list the fields methods" do
        @form.respond_to?('text_not_required').should be_true
      end
    end

    context "save/export :" do
      # TODO set exeception and write test for pdftk writting error.
      it "save should create the pdf with '_filled' file_name" do
        # TODO check presence of the file
        @form.save.should == path_to_pdf('fields_filled.pdf')
      end

      it "save should create pdf with specific path" do
        @form.save('/tmp/pdftk_test.pdf').should == '/tmp/pdftk_test.pdf'
      end

      it "should return a PdftkForms::Fdf object" do
        @form.to_fdf.should be_kind_of(PdftkForms::Fdf)
      end

      it "should return a PdftkForms::Fdf object with all inputs" do
        @form.to_fdf(true).should be_kind_of(PdftkForms::Fdf)
      end

      it "should return a PdftkForms::Xfdf object" do
        @form.to_xfdf.should be_kind_of(PdftkForms::Xfdf)
      end

      it "should return a PdftkForms::Xfdf object with all inputs" do
        @form.to_xfdf(true).should be_kind_of(PdftkForms::Xfdf)
      end
    end

    context "field_mapping_fill!" do
      it "should save the form with the fields filled in with their FieldName" do
        @form.field_mapping_fill!.save(@output = StringIO.new)
        @output.rewind
        @form_field_mapping = PdftkForms::Form.new(@output)
        @form.fields.each do |f|
          next unless f.type == 'Text'
          @form_field_mapping.get(f.name).value.should == f.name
        end
      end
    end
  end

end

