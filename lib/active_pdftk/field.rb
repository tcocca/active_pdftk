module ActivePdftk
  # Represents a fillable form field on a PDF form
  #
  # Contains a nice wrapper to check field flags to determine possible options
  class Field

    # @return [Hash] the attributes to construct the field
    attr_reader :attributes

    # @return [String] the default value of the field
    attr_reader :value_was

    # Create an instance based upon the attributes passed in.
    #
    # Sets the attr_reader +value_was+ to the default value of the field ('FieldValueDefault') or +nil+
    #
    # @param [Hash] attributes default statements as defined in DSL.
    # @option attributes [String] 'FieldType' the type of field
    # @option attributes [String] 'FieldName' the name of the field
    # @option attributes [String] 'FieldFlags' describes the attributes of the field (it is passed as a string but it is the integer representaion of a binary number)
    # @option attributes [String] 'FieldValueDefault' (optional) the default value of the field
    # @option attributes [String] 'FieldNameAlt' (optional) the alternative name (tooltip) of the field
    # @option attributes [String] 'FieldStateOption' (optional) an array of values for the field (used for Button and Choice fields)
    def initialize(attributes)
      @attributes = attributes
      @value_was = value
    end

    # @macro [new] global_method
    #   @note This is a global option for all field types
    # @macro [new] boolean
    #   @return [Boolean]
    # Boolean method to determine if the field is read only on the PDF form
    def read_only?
      check_bit_true(1)
    end

    # @macro global_method
    # @macro boolean
    # Boolean method to determine if the field is required on the PDF form
    def required?
      check_bit_true(2)
    end

    # @macro global_method
    # @macro boolean
    # Boolean method to determine if the field should not be exported to fill out the PDF form
    def no_export?
      check_bit_true(3)
    end

    # @macro [new] buttom_method
    #   @note This method only applies to 'Button' field types
    # @macro boolean
    # Boolean method to determine if the field is a 'push_button'
    def push_button?
      self.type == 'Button' && check_bit_true(17)
    end

    # @macro buttom_method
    # @macro boolean
    # Boolean method to determine if the field is a 'radio_button'
    def radio_button?
      self.type == 'Button' && !push_button? && check_bit_true(16)
    end

    # @macro buttom_method
    # @macro boolean
    # Boolean method to determine if the field is a 'check_box'
    def check_box?
      self.type == 'Button' && !push_button? && !radio_button?
    end

    # @macro [new] text_method
    #   @note This method only applies to 'Text' field types
    # @macro boolean
    # Boolean method to determine if the field has multiple lines of input
    def multiline?
      self.type == 'Text' && check_bit_true(13)
    end

    # @macro text_method
    # @macro boolean
    # Boolean method to determine if the field is a password input
    def password?
      self.type == 'Text' && check_bit_true(14)
    end

    # @macro text_method
    # @macro boolean
    # Boolean method to determine if the field is a file input
    def file?
      self.type == 'Text' && check_bit_true(21)
    end

    # @macro text_method
    # @macro boolean
    # Boolean method to determine if the field should not be spell checked
    def no_spell_check?
      self.type == 'Text' && check_bit_true(23)
    end

    # @macro text_method
    # @macro boolean
    # Boolean method to determine if the field does not scroll text
    def no_scroll?
      self.type == 'Text' && check_bit_true(24)
    end

    # @macro text_method
    # @macro boolean
    # Boolean method to determine if the field has comb formatting for display
    def comb?
      self.type == 'Text' && !(max_length.nil? || max_length.to_s.empty?) && check_bit_true(25)
    end

    # @macro text_method
    # @macro boolean
    # Boolean method to determine if the field is a rich_text input
    def rich_text?
      self.type == 'Text' && check_bit_true(26)
    end

    # @macro [new] choice_method
    #   @note This method only applies to 'Choice' field types
    # @macro boolean
    # Boolean method to determine if the field is a multiselect field
    def multiselect?
      self.type == 'Choice' && check_bit_true(22)
    end

    # @macro choice_method
    # @macro boolean
    # Boolean method to determine if the field is a combo box
    def combo_box?
      self.type == 'Choice' && check_bit_true(18)
    end

    # @macro choice_method
    # @macro boolean
    # Boolean method to determine if the field is a list box
    def list_box?
      !combo_box?
    end

    # @macro choice_method
    # @macro boolean
    # Boolean method to determine if the field lets you select from a list or enter you own value
    def editable_list?
      combo_box? && check_bit_true(19)
    end

    # @macro choice_method
    # @macro boolean
    # Boolean method to determine if the field sorts options alphabetically for display
    def sorted_list?
      self.type == 'Choice' && check_bit_true(20)
    end

    # @macro choice_method
    # @macro boolean
    # Boolean method to determine if the field should commit on value select
    def commit_on_change?
      self.type == 'Choice' && check_bit_true(27)
    end

    # @macro [new] radio_method
    #   @note This method only applies to radio button fields
    # @macro boolean
    # Boolean method to determine if the field is allowed to toggle to an off state when you click on a selected field again
    def no_toggle_off?
      radio_button? && check_bit_true(15)
    end

    # @macro radio_method
    # @macro boolean
    # Boolean method to determine if the field is part of a group that will change all values when an option is selected
    def in_unison?
      radio_button? && check_bit_true(26)
    end

    # Returns a string of a field type based on the 'FieldType' and the 'FieldFlags'
    #
    # Return values are designed to match the rails form builder field methods (with the exception of 'push_button' but that field does not do anything anyway)
    # @return [String] one of +radio_button, check_box, field_field, password_field, text_area, text_field, select, push_button+.
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
        if file?
          'file_field'
        elsif password?
          'password_field'
        elsif multiline?
          'text_area'
        else
          'text_field'
        end
      elsif self.type == 'Choice'
        'select'
      else
        self.type.downcase
      end
    end

    # Getter method for the 'FieldValue' attribute in the +attributes+ hash
    # @return [String]
    def value
      attributes['FieldValue']
    end

    # Setter method for the 'FieldValue' attribute in the +attributes+ hash.
    # The value does not change if the field is a read only true
    # @return [String]
    def value=(attr)
      attributes['FieldValue'] = attr unless read_only?
    end

    # Boolean method to tell whether the #value_was (default value from 'FieldValueDefault') is different from the the current #value.
    # Designed to mimick the dirty attributes of an ActiveRecord model
    #
    # @return [Boolean]
    def changed?
      @value_was != value
    end

    # Map of changes +value => [original value, new value]+ (only changed +value+ is supported).
    # Designed to mimick the dirty attributes of an ActiveRecord model
    #
    # @return [Hash] a hash like +'value' => [original_value, new_value]+
    def changes
      changed? ? {'value' => [@value_was, value]} : {}
    end

    # DSL for aliasing getter methods off of the +attributes+ hash instantiated in the #initialize method
    #
    # Allows us to give a more intuitive/shorter name to these methods
    # @return [String]
    def self.alias_attribute method_name, attribute_name
      define_method(method_name) do
        attributes[attribute_name]
      end
    end

    alias_attribute :name,          'FieldName'
    alias_attribute :type,          'FieldType'
    alias_attribute :flags,         'FieldFlags'
    alias_attribute :alt_name,      'FieldNameAlt'
    alias_attribute :options,       'FieldStateOption'
    alias_attribute :max_length,    'FieldMaxLength'
    alias_attribute :default_value, 'FieldValueDefault'

    private

    # @macro boolean
    # Boolean method to determine if a FieldFlag is 'true' based on the bit position in the FieldFlags integer when converted to a binary string
    def check_bit_true(bit_position)
      min_bit_value = "1"
      if bit_position > 1
        (bit_position - 1).times {min_bit_value << "0"}
      end
      self.flags.to_i >= min_bit_value.to_i(2) && self.flags.to_i.to_s(2)[-bit_position].chr == "1"
    end

  end
end
