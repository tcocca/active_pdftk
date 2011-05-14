require 'spec_helper'

describe PdftkForms::Field do
  
  context "aliased attributes" do
    before do
      @field = PdftkForms::Field.new(
        'FieldName' => 'test',
        'FieldType' => 'Text',
        'FieldValue' => '',
        'FieldFlags' => 4096
      )
    end
    
    it "should respond to" do
      @field.should respond_to(:name)
      @field.should respond_to(:type)
      @field.should respond_to(:value)
      @field.should respond_to(:flags)
      @field.should respond_to(:alt_name)
      @field.should respond_to(:options)
    end
    
    it "should return the attribute values for the aliased methods" do
      @field.name.should == 'test'
      @field.type.should == 'Text'
      @field.value.should == ''
      @field.flags.should == 4096
      @field.alt_name.should be_nil
      @field.options.should be_nil
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
      @field1 = PdftkForms::Field.new(@attributes)
      @field1.read_only?.should be_false
      @field2 = PdftkForms::Field.new(@attributes.merge('FieldFlags' => 2))
      @field2.read_only?.should be_false
    end
    
    it "should be true" do
      @field1 = PdftkForms::Field.new(@attributes.merge('FieldFlags' => 1))
      @field1.read_only?.should be_true
      @field2 = PdftkForms::Field.new(@attributes.merge('FieldFlags' => 3))
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
      @field1 = PdftkForms::Field.new(@attributes)
      @field1.required?.should be_false
      @field2 = PdftkForms::Field.new(@attributes.merge('FieldFlags' => 1))
      @field2.required?.should be_false
      @field3 = PdftkForms::Field.new(@attributes.merge('FieldFlags' => 4))
      @field3.required?.should be_false
    end
    
    it "should be true" do
      @field1 = PdftkForms::Field.new(@attributes.merge('FieldFlags' => 2))
      @field1.required?.should be_true
      @field2 = PdftkForms::Field.new(@attributes.merge('FieldFlags' => 3))
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
      @field1 = PdftkForms::Field.new(@attributes)
      @field1.multiline?.should be_false
      @field2 = PdftkForms::Field.new(@attributes.merge('FieldType' => 'Button', 'FieldFlags' => 4096))
      @field2.multiline?.should be_false
      @field3 = PdftkForms::Field.new(@attributes.merge('FieldFlags' => 4095))
      @field3.multiline?.should be_false
      @field3 = PdftkForms::Field.new(@attributes.merge('FieldFlags' => 8192))
      @field3.multiline?.should be_false
    end
    
    it "should be true" do
      @field1 = PdftkForms::Field.new(@attributes.merge('FieldFlags' => 4096))
      @field1.multiline?.should be_true
      @field2 = PdftkForms::Field.new(@attributes.merge('FieldFlags' => 12288))
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
      @field1 = PdftkForms::Field.new(@attributes)
      @field1.push_button?.should be_false
      @field2 = PdftkForms::Field.new(@attributes.merge('FieldType' => 'Button', 'FieldFlags' => 32768))
      @field2.push_button?.should be_false
      @field3 = PdftkForms::Field.new(@attributes.merge('FieldType' => 'Button', 'FieldFlags' => 131072))
      @field3.push_button?.should be_false
    end
    
    it "should be true" do
      @field1 = PdftkForms::Field.new(@attributes.merge('FieldFlags' => 65536))
      @field1.push_button?.should be_true
      @field2 = PdftkForms::Field.new(@attributes.merge('FieldFlags' => 196608))
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
      @field1 = PdftkForms::Field.new(@attributes)
      @field1.radio_button?.should be_false
      @field2 = PdftkForms::Field.new(@attributes.merge('FieldType' => 'Button', 'FieldFlags' => 65536))
      @field2.radio_button?.should be_false
      @field3 = PdftkForms::Field.new(@attributes.merge('FieldType' => 'Button', 'FieldFlags' => 32767))
      @field3.radio_button?.should be_false
      @field4 = PdftkForms::Field.new(@attributes.merge('FieldFlags' => 98304))
      @field4.radio_button?.should be_false
    end
    
    it "should be true" do
      @field1 = PdftkForms::Field.new(@attributes.merge('FieldFlags' => 32768))
      @field1.radio_button?.should be_true
      @field2 = PdftkForms::Field.new(@attributes.merge('FieldFlags' => 49153))
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
      @field2 = PdftkForms::Field.new(@attributes.merge('FieldType' => 'Button', 'FieldFlags' => 65536))
      @field2.check_box?.should be_false
      @field3 = PdftkForms::Field.new(@attributes.merge('FieldType' => 'Button', 'FieldFlags' => 32768))
      @field3.check_box?.should be_false
    end
    
    it "should be true" do
      @field1 = PdftkForms::Field.new(@attributes.merge('FieldFlags' => 0))
      @field1.check_box?.should be_true
      @field2 = PdftkForms::Field.new(@attributes.merge('FieldFlags' => 32767))
      @field2.check_box?.should be_true
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
      @field = PdftkForms::Field.new(@attributes.merge('FieldType' => 'Button'))
      @field.field_type.should == "check_box"
    end
    
    it "should return radio_button" do
      @field = PdftkForms::Field.new(@attributes.merge('FieldType' => 'Button', 'FieldFlags' => 32768))
      @field.field_type.should == "radio_button"
    end
    
    it "should return push_button" do
      @field = PdftkForms::Field.new(@attributes.merge('FieldType' => 'Button', 'FieldFlags' => 65536))
      @field.field_type.should == "push_button"
    end
    
    it "should return text_field" do
      @field = PdftkForms::Field.new(@attributes.merge('FieldType' => 'Text'))
      @field.field_type.should == "text_field"
    end
    
    it "should return text_area" do
      @field = PdftkForms::Field.new(@attributes.merge('FieldType' => 'Text', 'FieldFlags' => 4096))
      @field.field_type.should == "text_area"
    end
    
    it "should return select" do
      @field = PdftkForms::Field.new(@attributes.merge('FieldType' => 'Choice'))
      @field.field_type.should == "select"
    end
    
    it "should return lowercased FieldType" do
      @field = PdftkForms::Field.new(@attributes.merge('FieldType' => 'Something'))
      @field.field_type.should == "something"
    end
  end
  
end
