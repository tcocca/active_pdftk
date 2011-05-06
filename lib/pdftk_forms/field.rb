module PdftkForms
  # Represents a fillable form field on a particular PDF
  class Field
    
    def self.alias_attribute method_name, attribute_name
      define_method(method_name) do
        attributes[attribute_name]
      end
      define_method("#{method_name}=") do |value|
        attributes[attribute_name] = value
      end
    end
    
    def field_type
      if self.type == 'Button'
        if push_button?
          'push_button'
        elsif radio_button?
          'radio_button'
        else
          'check_box'
        end
      elsif self.type == 'Text'
        multiline? ? 'text_area' : 'text_field'
      elsif self.type == 'Choice'
        'select'
      else
        self.type.downcase
      end
    end
    
    def required?
      self.flags.to_i >= 2 && self.flags.to_i.to_s(2)[-2].chr == "1"
    end
    
    def multiline?
      self.type == 'Text' && self.flags.to_i >= 4096 && self.flags.to_i.to_s(2)[-13].chr == "1"
    end
    
    def push_button?
      self.type == 'Button' && self.flags.to_i >= 65536 && self.flags.to_i.to_s(2)[-17].chr == "1"
    end
    
    def radio_button?
      self.type == 'Button' && !push_button? && self.flags.to_i >= 32768 && self.flags.to_i.to_s(2)[-16].chr == "1"
    end
    
    def check_box?
      self.type == 'Button' && !push_button? && !radio_button?
    end
    
    attr_accessor :attributes
    
    def initialize attributes
      @attributes = attributes
    end
    
    alias_attribute :name,  'FieldName'
    alias_attribute :type,  'FieldType'
    alias_attribute :value, 'FieldValue'
    alias_attribute :flags, 'FieldFlags'
    alias_attribute :alt_name, 'FieldNameAlt'
    alias_attribute :options, 'FieldStateOption'
  end
  
end
