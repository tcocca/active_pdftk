require 'spec_helper'

describe ActivePdftk::Field do

  context "aliased attributes" do
    before do
      @field = ActivePdftk::Field.new(
        'FieldName' => 'test',
        'FieldType' => 'Text',
        'FieldValue' => '',
        'FieldFlags' => 4096
      )
    end

    it "should respond to" do
      @field.should respond_to(:name)
      @field.should respond_to(:type)
      @field.should respond_to(:flags)
      @field.should respond_to(:alt_name)
      @field.should respond_to(:options)
      @field.should respond_to(:max_length)
    end

    it "should return the attribute values for the aliased methods" do
      @field.name.should == 'test'
      @field.type.should == 'Text'
      @field.value.should == ''
      @field.default_value.should be_nil
      @field.flags.should == 4096
      @field.alt_name.should be_nil
      @field.options.should be_nil
      @field.max_length.should be_nil
    end
  end

  context "aliased attributes defaults" do
    before do
      @field = ActivePdftk::Field.new(
        'FieldName' => 'test',
        'FieldType' => 'Text',
        'FieldValue' => 'pdftk_test',
        'FieldValueDefault' => 'pdftk_test',
        'FieldFlags' => '0',
        'FieldMaxLength' => '100',
        'FieldNameAlt' => 'Tooltip Text'
      )
    end
    
    it "should return the attribute values for the aliased methods" do
      @field.name.should == 'test'
      @field.type.should == 'Text'
      @field.value.should == 'pdftk_test'
      @field.default_value.should == 'pdftk_test'
      @field.flags.should == '0'
      @field.alt_name.should == 'Tooltip Text'
      @field.options.should be_nil
      @field.max_length.should == '100'
    end
  end

  context 'read_only?' do
    before do
      @attributes = {
        'FieldName' => 'test',
        'FieldType' => 'Text',
        'FieldValue' => '',
        'FieldFlags' => 0
      }
    end

    it "should be false" do
      @field1 = ActivePdftk::Field.new(@attributes)
      @field1.read_only?.should be_false
      @field2 = ActivePdftk::Field.new(@attributes.merge('FieldFlags' => 2))
      @field2.read_only?.should be_false
    end

    it "should be true" do
      @field1 = ActivePdftk::Field.new(@attributes.merge('FieldFlags' => 1))
      @field1.read_only?.should be_true
      @field2 = ActivePdftk::Field.new(@attributes.merge('FieldFlags' => 3))
      @field2.read_only?.should be_true
    end
  end

  context 'required?' do
    before do
      @attributes = {
        'FieldName' => 'test',
        'FieldType' => 'Text',
        'FieldValue' => '',
        'FieldFlags' => 0
      }
    end

    it "should be false" do
      @field1 = ActivePdftk::Field.new(@attributes)
      @field1.required?.should be_false
      @field2 = ActivePdftk::Field.new(@attributes.merge('FieldFlags' => 1))
      @field2.required?.should be_false
      @field3 = ActivePdftk::Field.new(@attributes.merge('FieldFlags' => 4))
      @field3.required?.should be_false
    end

    it "should be true" do
      @field1 = ActivePdftk::Field.new(@attributes.merge('FieldFlags' => 2))
      @field1.required?.should be_true
      @field2 = ActivePdftk::Field.new(@attributes.merge('FieldFlags' => 3))
      @field2.required?.should be_true
    end
  end

  context 'multiline? text fields' do
    before do
      @attributes = {
        'FieldName' => 'test',
        'FieldType' => 'Text',
        'FieldValue' => '',
        'FieldFlags' => 0
      }
    end

    it "should be false" do
      @field1 = ActivePdftk::Field.new(@attributes)
      @field1.multiline?.should be_false
      @field2 = ActivePdftk::Field.new(@attributes.merge('FieldType' => 'Button', 'FieldFlags' => 4096))
      @field2.multiline?.should be_false
      @field3 = ActivePdftk::Field.new(@attributes.merge('FieldFlags' => 4095))
      @field3.multiline?.should be_false
      @field3 = ActivePdftk::Field.new(@attributes.merge('FieldFlags' => 8192))
      @field3.multiline?.should be_false
    end

    it "should be true" do
      @field1 = ActivePdftk::Field.new(@attributes.merge('FieldFlags' => 4096))
      @field1.multiline?.should be_true
      @field2 = ActivePdftk::Field.new(@attributes.merge('FieldFlags' => 12288))
      @field2.multiline?.should be_true
    end
  end

  context 'push_button?' do
    before do
      @attributes = {
        'FieldName' => 'test',
        'FieldType' => 'Button',
        'FieldValue' => '',
        'FieldFlags' => 0
      }
    end

    it "should be false" do
      @field1 = ActivePdftk::Field.new(@attributes)
      @field1.push_button?.should be_false
      @field2 = ActivePdftk::Field.new(@attributes.merge('FieldType' => 'Button', 'FieldFlags' => 32768))
      @field2.push_button?.should be_false
      @field3 = ActivePdftk::Field.new(@attributes.merge('FieldType' => 'Button', 'FieldFlags' => 131072))
      @field3.push_button?.should be_false
    end

    it "should be true" do
      @field1 = ActivePdftk::Field.new(@attributes.merge('FieldFlags' => 65536))
      @field1.push_button?.should be_true
      @field2 = ActivePdftk::Field.new(@attributes.merge('FieldFlags' => 196608))
      @field2.push_button?.should be_true
    end
  end

  context 'radio_button?' do
    before do
      @attributes = {
        'FieldName' => 'test',
        'FieldType' => 'Button',
        'FieldValue' => '',
        'FieldFlags' => 0
      }
    end

    it "should be false" do
      @field1 = ActivePdftk::Field.new(@attributes)
      @field1.radio_button?.should be_false
      @field2 = ActivePdftk::Field.new(@attributes.merge('FieldType' => 'Button', 'FieldFlags' => 65536))
      @field2.radio_button?.should be_false
      @field3 = ActivePdftk::Field.new(@attributes.merge('FieldType' => 'Button', 'FieldFlags' => 32767))
      @field3.radio_button?.should be_false
      @field4 = ActivePdftk::Field.new(@attributes.merge('FieldFlags' => 98304))
      @field4.radio_button?.should be_false
    end

    it "should be true" do
      @field1 = ActivePdftk::Field.new(@attributes.merge('FieldFlags' => 32768))
      @field1.radio_button?.should be_true
      @field2 = ActivePdftk::Field.new(@attributes.merge('FieldFlags' => 49153))
      @field2.radio_button?.should be_true
    end
  end

  context 'check_box?' do
    before do
      @attributes = {
        'FieldName' => 'test',
        'FieldType' => 'Button',
        'FieldValue' => '',
        'FieldFlags' => 0
      }
    end

    it "should be false" do
      @field1 = ActivePdftk::Field.new(@attributes.merge('FieldType' => 'Button', 'FieldFlags' => 65536))
      @field1.check_box?.should be_false
      @field2 = ActivePdftk::Field.new(@attributes.merge('FieldType' => 'Button', 'FieldFlags' => 32768))
      @field2.check_box?.should be_false
    end

    it "should be true" do
      @field1 = ActivePdftk::Field.new(@attributes.merge('FieldFlags' => 0))
      @field1.check_box?.should be_true
      @field2 = ActivePdftk::Field.new(@attributes.merge('FieldFlags' => 32767))
      @field2.check_box?.should be_true
    end
  end

  context 'no_export?' do
    before do
      @attributes = {
        'FieldName' => 'test',
        'FieldType' => 'Button',
        'FieldValue' => '',
        'FieldFlags' => 0
      }
    end

    it "should be false" do
      @field1 = ActivePdftk::Field.new(@attributes)
      @field1.no_export?.should be_false
      @field2 = ActivePdftk::Field.new(@attributes.merge('FieldFlags' => 3))
      @field2.no_export?.should be_false
      @field3 = ActivePdftk::Field.new(@attributes.merge('FieldFlags' => 8))
      @field3.no_export?.should be_false
    end

    it "should be true" do
      @field1 = ActivePdftk::Field.new(@attributes.merge('FieldFlags' => 4))
      @field1.no_export?.should be_true
      @field2 = ActivePdftk::Field.new(@attributes.merge('FieldFlags' => 6))
      @field2.no_export?.should be_true
    end
  end

  context "password?" do
    it "should be true" do
      @field1 = ActivePdftk::Field.new({'FieldName' => 'test', 'FieldType' => 'Text', 'FieldFlags' => 8192})
      @field1.password?.should be_true
    end
  end

  context "file?" do
    it "should be true" do
      @field1 = ActivePdftk::Field.new({'FieldName' => 'test', 'FieldType' => 'Text', 'FieldFlags' => 1048576})
      @field1.file?.should be_true
    end
  end

  context "no_spell_check?" do
    it "should be true" do
      @field1 = ActivePdftk::Field.new({'FieldName' => 'test', 'FieldType' => 'Text', 'FieldFlags' => 4194304})
      @field1.no_spell_check?.should be_true
    end
  end

  context "no_scroll?" do
    it "should be true" do
      @field1 = ActivePdftk::Field.new({'FieldName' => 'test', 'FieldType' => 'Text', 'FieldFlags' => 8388608})
      @field1.no_scroll?.should be_true
    end
  end

  context "comb?" do
    it "should be false" do
      @field1 = ActivePdftk::Field.new({'FieldName' => 'test', 'FieldType' => 'Text', 'FieldFlags' => 16777216})
      @field1.comb?.should be_false
    end
    
    it "should be true" do
      @field1 = ActivePdftk::Field.new({'FieldName' => 'test', 'FieldType' => 'Text', 'FieldMaxLength' => 100, 'FieldFlags' => 16777216})
      @field1.comb?.should be_true
    end
  end

  context "rich_text?" do
    it "should be true" do
      @field1 = ActivePdftk::Field.new({'FieldName' => 'test', 'FieldType' => 'Text', 'FieldFlags' => 33554432})
      @field1.rich_text?.should be_true
    end
  end

  context "multiselect?" do
    it "should be true" do
      @field1 = ActivePdftk::Field.new({'FieldName' => 'test', 'FieldType' => 'Choice', 'FieldFlags' => 2097152})
      @field1.multiselect?.should be_true
    end
  end

  context "combo_box?" do
    it "should be true" do
      @field1 = ActivePdftk::Field.new({'FieldName' => 'test', 'FieldType' => 'Choice', 'FieldFlags' => 131072})
      @field1.combo_box?.should be_true
    end
  end

  context "list_box?" do
    it "should be true" do
      @field1 = ActivePdftk::Field.new({'FieldName' => 'test', 'FieldType' => 'Choice', 'FieldFlags' => 131071})
      @field1.list_box?.should be_true
    end
  end

  context "editable_list?" do
    it "should be false" do
      @field1 = ActivePdftk::Field.new({'FieldName' => 'test', 'FieldType' => 'Choice', 'FieldFlags' => 262144})
      @field1.editable_list?.should be_false
    end

    it "should be true" do
      @field1 = ActivePdftk::Field.new({'FieldName' => 'test', 'FieldType' => 'Choice', 'FieldFlags' => 393216})
      @field1.editable_list?.should be_true
    end
  end

  context "sorted_list?" do
    it "should be true" do
      @field1 = ActivePdftk::Field.new({'FieldName' => 'test', 'FieldType' => 'Choice', 'FieldFlags' => 524288})
      @field1.sorted_list?.should be_true
    end
  end

  context "commit_on_change?" do
    it "should be true" do
      @field1 = ActivePdftk::Field.new({'FieldName' => 'test', 'FieldType' => 'Choice', 'FieldFlags' => 67108864})
      @field1.commit_on_change?.should be_true
    end
  end

  context "no_toggle_off?" do
    it "should be true" do
      @field1 = ActivePdftk::Field.new({'FieldName' => 'test', 'FieldType' => 'Button', 'FieldFlags' => 49152})
      @field1.no_toggle_off?.should be_true
    end

    it "should be false" do
      @field1 = ActivePdftk::Field.new({'FieldName' => 'test', 'FieldType' => 'Button', 'FieldFlags' => 81920})
      @field1.no_toggle_off?.should be_false
    end
  end

  context "in_unison?" do
    it "should be true" do
      @field1 = ActivePdftk::Field.new({'FieldName' => 'test', 'FieldType' => 'Button', 'FieldFlags' => 33587200})
      @field1.in_unison?.should be_true
    end

    it "should be false" do
      @field1 = ActivePdftk::Field.new({'FieldName' => 'test', 'FieldType' => 'Button', 'FieldFlags' => 33652736})
      @field1.in_unison?.should be_false
    end
  end

  context 'field_type' do
    before do
      @attributes = {
        'FieldName' => 'test',
        'FieldValue' => '',
        'FieldFlags' => 0
      }
    end

    it "should reutrn check_box" do
      @field = ActivePdftk::Field.new(@attributes.merge('FieldType' => 'Button'))
      @field.field_type.should == "check_box"
    end

    it "should return radio_button" do
      @field = ActivePdftk::Field.new(@attributes.merge('FieldType' => 'Button', 'FieldFlags' => 32768))
      @field.field_type.should == "radio_button"
    end

    it "should return push_button" do
      @field = ActivePdftk::Field.new(@attributes.merge('FieldType' => 'Button', 'FieldFlags' => 65536))
      @field.field_type.should == "push_button"
    end

    it "should return text_field" do
      @field = ActivePdftk::Field.new(@attributes.merge('FieldType' => 'Text'))
      @field.field_type.should == "text_field"
    end

    it "should return text_area" do
      @field = ActivePdftk::Field.new(@attributes.merge('FieldType' => 'Text', 'FieldFlags' => 4096))
      @field.field_type.should == "text_area"
    end

    it "should return password_field" do
      @field = ActivePdftk::Field.new(@attributes.merge('FieldType' => 'Text', 'FieldFlags' => 8192))
      @field.field_type.should == "password_field"
    end

    it "should return file_field" do
      @field = ActivePdftk::Field.new(@attributes.merge('FieldType' => 'Text', 'FieldFlags' => 1048576))
      @field.field_type.should == "file_field"
    end

    it "should return select" do
      @field = ActivePdftk::Field.new(@attributes.merge('FieldType' => 'Choice'))
      @field.field_type.should == "select"
    end

    it "should return lowercased FieldType" do
      @field = ActivePdftk::Field.new(@attributes.merge('FieldType' => 'Something'))
      @field.field_type.should == "something"
    end
  end

  context "value" do
    before do
      @field = ActivePdftk::Field.new(
        'FieldName' => 'test',
        'FieldType' => 'Text',
        'FieldValue' => '',
        'FieldFlags' => 4096
      )
    end
    
    context "setting value" do
      it { @field.value.should == '' }

      it "should return the new value" do
        @field.value = 'test'
        @field.value.should == 'test'
      end

      it "should set #value_was" do
        @field.value_was.should == ''
        @field.value = 'test'
        @field.value_was.should == ''
      end
    end

    context "dirty" do
      it "should determine #changed?" do
        @field.changed?.should be_false
        @field.value = 'test'
        @field.changed?.should be_true
      end

      it "should give the user the changes" do
        @field.changes.should == {}
        @field.value = 'test'
        @field.changes.should == {'value' => ['', 'test']}
      end
    end
  end

  context "setting value on readonly" do
    before do
      @field = ActivePdftk::Field.new(
        'FieldName' => 'test',
        'FieldType' => 'Text',
        'FieldValue' => '',
        'FieldFlags' => 1
      )
    end

    it "should not change the value" do
      @field.changed?.should be_false
      @field.value = 'test'
      @field.value.should == ''
      @field.changed?.should be_false
      @field.changes.should == {}
    end
  end

  context 'nil initial value' do
    context 'no FieldValue data' do
      before do
        @field = ActivePdftk::Field.new(
          'FieldName' => 'test',
          'FieldType' => 'Text',
          'FieldFlags' => 2
        )
      end

      it { @field.value_was.should == nil}

      it "should return nil in the changes" do
        @field.value = 'test'
        @field.changes.should == {'value' => [nil, 'test']}
      end
    end

    context 'explicity nil FieldValue data' do
      before do
        @field = ActivePdftk::Field.new(
          'FieldName' => 'test',
          'FieldType' => 'Text',
          'FieldValue' => nil,
          'FieldFlags' => 2
        )
      end

      it { @field.value_was.should == nil}

      it "should return nil in the changes" do
        @field.value = 'test'
        @field.changes.should == {'value' => [nil, 'test']}
      end
    end
  end

end
