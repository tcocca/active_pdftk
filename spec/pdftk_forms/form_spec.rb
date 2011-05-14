require 'spec_helper'

describe PdftkForms::Form do
  context "new" do
    it "should create a PdftkForms::Form object" do
      @form = PdftkForms::Form.new(path_to_pdf('fields'))
      @form.should be_kind_of(PdftkForms::Form)
      @form.template.should == path_to_pdf('fields')
    end
  end

  context "Instantiate a Form, " do
    before do
      @form = PdftkForms::Form.new(path_to_pdf('fields'))
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
    end

    context "to_h" do
      it "should return the reduced hash" do
        @form.dummy_filling!.to_h.should == {"list_box"=>"sam", "text_not_required"=>"text_not_required", "text_area"=>"text_area", "text_required"=>"text_required"}
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
        @form.save.should == path_to_pdf('fields_filled')
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

    # Cannot test while flatten is forced.
    context "dummy_filling!" do
      it "should save correctly the dummy filled form" do
        @form.dummy_filling!
        @form_dummy = PdftkForms::Form.new(@form.save(@form.template + '.dummy'))
#        @form.fields.each do |f|
#          next unless f.type == 'Text'
#          puts f.name
#          @form_dummy.get(f.name).value.should == f.name
#        end
      end
    end
  end

end

