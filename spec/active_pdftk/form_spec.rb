require 'spec_helper'

describe ActivePdftk::Form do
  context "new" do
    it "should create a ActivePdftk::Form object" do
      @form = ActivePdftk::Form.new(path_to_pdf('fields.pdf'))
      @form.should be_kind_of(ActivePdftk::Form)
      @form.template.should == path_to_pdf('fields.pdf')
    end
  end

  context "Instantiate a Form, " do
    before do
      @form = ActivePdftk::Form.new(path_to_pdf('fields.pdf'))
    end

    context "fields" do
      it "should get the total number of fields" do
        @form.fields.size.should == 28
      end

      it "should return an array of ActivePdftk::Field objects" do
        @form.fields.each do |field|
          field.should be_kind_of(ActivePdftk::Field)
        end
      end

      it "should set the field data" do
        fields = @form.fields
        fields[0].name.should == "text_not_required"
        fields[0].value.should == nil
        fields[0].default_value.should == nil
        fields[0].type.should == "Text"
        fields[0].flags.should == "0"
        fields[0].alt_name.should == nil
        fields[0].options.should == nil
        fields[0].field_type.should == "text_field"
        fields[0].max_length == nil
        fields[0].required?.should == false

        fields[1].name.should == "combo_box"
        fields[1].value.should == nil
        fields[1].default_value.should == nil
        fields[1].type.should == "Choice"
        fields[1].flags.should == "131072"
        fields[1].alt_name.should == nil
        fields[1].options.should == ["Jason", "Tom"]
        fields[1].field_type.should == "select"
        fields[1].max_length == nil
        fields[1].combo_box?.should == true

        fields[2].name.should == "text_required"
        fields[2].value.should == nil
        fields[2].default_value.should == nil
        fields[2].type.should == "Text"
        fields[2].flags.should == "2"
        fields[2].alt_name.should == nil
        fields[2].options.should == nil
        fields[2].field_type.should == "text_field"
        fields[2].max_length == nil
        fields[2].required?.should == true

        fields[3].name.should == "check_box"
        fields[3].value.should == nil
        fields[3].default_value.should == nil
        fields[3].type.should == "Button"
        fields[3].flags.should == "0"
        fields[3].alt_name.should == nil
        fields[3].options.should == ["Off", "Yes"]
        fields[3].field_type.should == "check_box"
        fields[3].max_length == nil
        fields[3].check_box?.should == true

        fields[4].name.should == "radio_button"
        fields[4].value.should == nil
        fields[4].default_value.should == nil
        fields[4].type.should == "Button"
        fields[4].flags.should == "49152"
        fields[4].alt_name.should == nil
        fields[4].options.should == ["No", "Off", "Yes"]
        fields[4].field_type.should == "radio_button"
        fields[4].max_length == nil
        fields[4].radio_button?.should == true

        fields[5].name.should == "list_box"
        fields[5].value.should == nil
        fields[5].default_value.should == nil
        fields[5].type.should == "Choice"
        fields[5].flags.should == "0"
        fields[5].alt_name.should == nil
        fields[5].options.should == ["dave", "sam"]
        fields[5].field_type.should == "select"
        fields[5].max_length == nil
        fields[5].list_box?.should == true

        fields[6].name.should == "button"
        fields[6].value.should == nil
        fields[6].default_value.should == nil
        fields[6].type.should == "Button"
        fields[6].flags.should == "65536"
        fields[6].alt_name.should == "Push Me"
        fields[6].options.should == nil
        fields[6].field_type.should == "push_button"
        fields[6].max_length == nil
        fields[6].push_button?.should == true

        fields[7].name.should == "text_area"
        fields[7].value.should == nil
        fields[7].default_value.should == nil
        fields[7].type.should == "Text"
        fields[7].flags.should == "4096"
        fields[7].alt_name.should == nil
        fields[7].options.should == nil
        fields[7].field_type.should == "text_area"
        fields[7].max_length == nil
        fields[7].multiline?.should == true

        fields[8].name.should == "read_only"
        fields[8].value.should == "read_only"
        fields[8].default_value.should == "read_only"
        fields[8].type.should == "Text"
        fields[8].flags.should == "1"
        fields[8].alt_name.should == nil
        fields[8].options.should == nil
        fields[8].field_type.should == "text_field"
        fields[8].max_length == nil
        fields[8].read_only?.should == true

        fields[9].name.should == "password"
        fields[9].value.should == nil
        fields[9].default_value.should == nil
        fields[9].type.should == "Text"
        fields[9].flags.should == "12591106"
        fields[9].alt_name.should == nil
        fields[9].options.should == nil
        fields[9].field_type.should == "password_field"
        fields[9].max_length == nil
        fields[9].password?.should == true

        fields[10].name.should == "file"
        fields[10].value.should == nil
        fields[10].default_value.should == nil
        fields[10].type.should == "Text"
        fields[10].flags.should == "5242880"
        fields[10].alt_name.should == nil
        fields[10].options.should == nil
        fields[10].field_type.should == "file_field"
        fields[10].max_length == nil
        fields[10].file?.should == true

        fields[11].name.should == "locked_field"
        fields[11].value.should == nil
        fields[11].default_value.should == nil
        fields[11].type.should == "Text"
        fields[11].flags.should == "12582912"
        fields[11].alt_name.should == nil
        fields[11].options.should == nil
        fields[11].field_type.should == "text_field"
        fields[11].max_length == nil
        fields[11].no_scroll?.should == true
        fields[11].no_spell_check?.should == true

        fields[12].name.should == "default_value"
        fields[12].value.should == "default_value"
        fields[12].default_value.should == "default_value"
        fields[12].type.should == "Text"
        fields[12].flags.should == "12582912"
        fields[12].alt_name.should == "Tooltip Text"
        fields[12].options.should == nil
        fields[12].field_type.should == "text_field"
        fields[12].max_length == nil

        fields[13].name.should == "multi_line"
        fields[13].value.should == nil
        fields[13].default_value.should == nil
        fields[13].type.should == "Text"
        fields[13].flags.should == "12587008"
        fields[13].alt_name.should == nil
        fields[13].options.should == nil
        fields[13].field_type.should == "text_area"
        fields[13].max_length == nil
        fields[13].multiline?.should == true

        fields[14].name.should == "scroll_text"
        fields[14].value.should == nil
        fields[14].default_value.should == nil
        fields[14].type.should == "Text"
        fields[14].flags.should == "4194304"
        fields[14].alt_name.should == nil
        fields[14].options.should == nil
        fields[14].field_type.should == "text_field"
        fields[14].max_length == nil
        fields[14].no_scroll?.should == false

        fields[15].name.should == "max_100"
        fields[15].value.should == nil
        fields[15].default_value.should == nil
        fields[15].type.should == "Text"
        fields[15].flags.should == "12582912"
        fields[15].alt_name.should == nil
        fields[15].options.should == nil
        fields[15].field_type.should == "text_field"
        fields[15].max_length == "100"

        fields[16].name.should == "rich_text"
        fields[16].value.should == nil
        fields[16].default_value.should == nil
        fields[16].type.should == "Text"
        fields[16].flags.should == "46137344"
        fields[16].alt_name.should == nil
        fields[16].options.should == nil
        fields[16].field_type.should == "text_field"
        fields[16].max_length == nil
        fields[16].rich_text?.should == true

        fields[17].name.should == "check_spellings"
        fields[17].value.should == nil
        fields[17].default_value.should == nil
        fields[17].type.should == "Text"
        fields[17].flags.should == "8388608"
        fields[17].alt_name.should == nil
        fields[17].options.should == nil
        fields[17].field_type.should == "text_field"
        fields[17].max_length == nil
        fields[17].no_spell_check?.should == false

        fields[18].name.should == "comb_20"
        fields[18].value.should == nil
        fields[18].default_value.should == nil
        fields[18].type.should == "Text"
        fields[18].flags.should == "29360128"
        fields[18].alt_name.should == nil
        fields[18].options.should == nil
        fields[18].field_type.should == "text_field"
        fields[18].max_length == "20"
        fields[18].comb?.should == true

        fields[19].name.should == "edit_combo"
        fields[19].value.should == nil
        fields[19].default_value.should == nil
        fields[19].type.should == "Choice"
        fields[19].flags.should == "4587520"
        fields[19].alt_name.should == nil
        fields[19].options.should == ['Marco', 'Tom']
        fields[19].field_type.should == "select"
        fields[19].max_length == nil
        fields[19].editable_list?.should == true

        fields[20].name.should == "sort_combo"
        fields[20].value.should == nil
        fields[20].default_value.should == nil
        fields[20].type.should == "Choice"
        fields[20].flags.should == "4849664"
        fields[20].alt_name.should == nil
        fields[20].options.should == ['John', 'Matt']
        fields[20].field_type.should == "select"
        fields[20].max_length == nil
        fields[20].sorted_list?.should == true

        fields[21].name.should == "commit_combo"
        fields[21].value.should == nil
        fields[21].default_value.should == nil
        fields[21].type.should == "Choice"
        fields[21].flags.should == "71434242"
        fields[21].alt_name.should == nil
        fields[21].options.should == ['Jim', 'Steve']
        fields[21].field_type.should == "select"
        fields[21].max_length == nil
        fields[21].commit_on_change?.should == true

        fields[22].name.should == "sort_list"
        fields[22].value.should == nil
        fields[22].default_value.should == nil
        fields[22].type.should == "Choice"
        fields[22].flags.should == "524288"
        fields[22].alt_name.should == nil
        fields[22].options.should == ['Jason', 'Matt']
        fields[22].field_type.should == "select"
        fields[22].max_length == nil
        fields[22].sorted_list?.should == true

        fields[23].name.should == "multi_select_list"
        fields[23].value.should == nil
        fields[23].default_value.should == nil
        fields[23].type.should == "Choice"
        fields[23].flags.should == "2097152"
        fields[23].alt_name.should == nil
        fields[23].options.should == ['John', 'Tom']
        fields[23].field_type.should == "select"
        fields[23].max_length == nil
        fields[23].multiselect?.should == true

        fields[24].name.should == "default_checked"
        fields[24].value.should == "Yes"
        fields[24].default_value.should == nil
        fields[24].type.should == "Button"
        fields[24].flags.should == "0"
        fields[24].alt_name.should == nil
        fields[24].options.should == ['Off', 'Yes']
        fields[24].field_type.should == "check_box"
        fields[24].max_length == nil
        fields[24].required?.should == false

        fields[25].name.should == "default_radio"
        fields[25].value.should == "Yes"
        fields[25].default_value.should == nil
        fields[25].type.should == "Button"
        fields[25].flags.should == "33603584"
        fields[25].alt_name.should == nil
        fields[25].options.should == ['Both', 'No', 'Off', 'Yes']
        fields[25].field_type.should == "radio_button"
        fields[25].max_length == nil
        fields[25].radio_button?.should == true

        fields[26].name.should == "default_list"
        fields[26].value.should == "Tom"
        fields[26].default_value.should == "Tom"
        fields[26].type.should == "Choice"
        fields[26].flags.should == "0"
        fields[26].alt_name.should == nil
        fields[26].options.should == ['Matt', 'Tom']
        fields[26].field_type.should == "select"
        fields[26].max_length == nil
        fields[26].list_box?.should == true

        fields[27].name.should == "default_combo"
        fields[27].value.should == "Marco"
        fields[27].default_value.should == "Marco"
        fields[27].type.should == "Choice"
        fields[27].flags.should == "4587520"
        fields[27].alt_name.should == nil
        fields[27].options.should == ['Marco', 'Tom']
        fields[27].field_type.should == "select"
        fields[27].max_length == nil
        fields[27].combo_box?.should == true
      end
    end

    context "to_h" do
      it "should return the reduced hash" do
        @form.field_mapping_fill!.to_h.should == {
          "default_radio"=>"Yes", "scroll_text"=>"scroll_text", "default_value"=>"default_value", "read_only"=>"read_only", 
          "default_checked"=>"Yes", "check_spellings"=>"check_spellings", "max_100"=>"max_100", "rich_text"=>"rich_text", 
          "text_not_required"=>"text_not_required", "default_list"=>"Tom", "default_combo"=>"Marco", "locked_field"=>"locked_field", 
          "text_area"=>"text_area", "comb_20"=>"comb_20", "multi_line"=>"multi_line", "file"=>"file", "password"=>"password", 
          "text_required"=>"text_required"
        }
      end

      it "(true) should return the full hash" do
        @form.to_h(true).should == {
          "default_radio"=>"Yes", "scroll_text"=>"", "button"=>"", "default_value"=>"default_value", "read_only"=>"read_only", "default_checked"=>"Yes", 
          "sort_list"=>"", "check_spellings"=>"", "radio_button"=>"", "check_box"=>"", "edit_combo"=>"", "list_box"=>"", "sort_combo"=>"", "max_100"=>"", 
          "rich_text"=>"", "text_not_required"=>"", "default_list"=>"Tom", "default_combo"=>"Marco", "multi_select_list"=>"", "locked_field"=>"", 
          "text_area"=>"", "commit_combo"=>"", "comb_20"=>"", "multi_line"=>"", "file"=>"", "combo_box"=>"", "password"=>"", "text_required"=>""
        }
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

    context "save" do
      # TODO set exeception and write test for pdftk writting error.
      it "save should save the form as StringIO" do
        # TODO check presence of the file
        @form.save.should be_kind_of(StringIO)
      end

      it "save should create pdf with specific path" do
        @form.save('/tmp/pdftk_test.pdf').should == '/tmp/pdftk_test.pdf'
      end
    end

    context "save!" do
      it "should return the modified template as StringIO if @template is a string" do
        @form.save!.should be_kind_of(StringIO)
      end

      it "should return StringIO if the template is StringIO" do
        stringio = StringIO.new(path_to_pdf('fields.pdf'))
        stringio.rewind
        @form = ActivePdftk::Form.new(stringio)
        @form.save!.should be_kind_of(StringIO)
      end

    end

    context "fdf/xfdf" do
      it "should return a ActivePdftk::Fdf object" do
        @form.to_fdf.should be_kind_of(ActivePdftk::Fdf)
      end

      it "should return a ActivePdftk::Fdf object with all inputs" do
        @form.to_fdf(true).should be_kind_of(ActivePdftk::Fdf)
      end

      it "should return a ActivePdftk::Xfdf object" do
        @form.to_xfdf.should be_kind_of(ActivePdftk::Xfdf)
      end

      it "should return a ActivePdftk::Xfdf object with all inputs" do
        @form.to_xfdf(true).should be_kind_of(ActivePdftk::Xfdf)
      end
    end

    context "field_mapping_fill!" do
      it "should save the form with the fields filled in with their FieldName" do
        @form.field_mapping_fill!.save(@output = StringIO.new)
        @output.rewind
        @form_field_mapping = ActivePdftk::Form.new(@output)
        @form.fields.each do |f|
          next unless f.type == 'Text'
          @form_field_mapping.get(f.name).value.should == f.name
        end
      end
    end
  end

end

