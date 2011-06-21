module PdftkForms
  # Represents a fillable form field on a particular PDF
  class Field

    attr_reader :attributes, :value_was

    def initialize(attributes)
      @attributes = attributes
      @value_was = value
    end

    # Global Options
    def read_only?
      check_bit_true(1)
    end

    def required?
      check_bit_true(2)
    end

    def no_export?
      check_bit_true(3)
    end

    # Button Options
    def push_button?
      self.type == 'Button' && check_bit_true(17)
    end

    def radio_button?
      self.type == 'Button' && !push_button? && check_bit_true(16)
    end

    def check_box?
      self.type == 'Button' && !push_button? && !radio_button?
    end

    # Text Field Options
    def multiline?
      self.type == 'Text' && check_bit_true(13)
    end

    def password?
      self.type == 'Text' && check_bit_true(14)
    end

    def file?
      self.type == 'Text' && check_bit_true(21)
    end

    def no_spell_check?
      self.type == 'Text' && check_bit_true(23)
    end

    def no_scroll?
      self.type == 'Text' && check_bit_true(24)
    end

    def comb?
      self.type == 'Text' && !(max_length.nil? || max_length.to_s.empty?) && check_bit_true(25)
    end

    def rich_text?
      self.type == 'Text' && check_bit_true(26)
    end

    # Choice Field Options
    def multiselect?
      self.type == 'Choice' && check_bit_true(22)
    end

    def combo_box?
      self.type == 'Choice' && check_bit_true(18)
    end

    def list_box?
      !combo_box?
    end

    def editable_list?
      combo_box? && check_bit_true(19)
    end

    def sorted_list?
      self.type == 'Choice' && check_bit_true(20)
    end

    def commit_on_change?
      self.type == 'Choice' && check_bit_true(27)
    end

    # Radio Button Options
    def no_toggle_off?
      radio_button? && check_bit_true(15)
    end

    def in_unison?
      radio_button? && check_bit_true(26)
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

    def value
      attributes['FieldValue']
    end

    def value=(attr)
      attributes['FieldValue'] = attr unless read_only?
    end

    def changed?
      @value_was != value
    end

    def changes
      changed? ? {'value' => [@value_was, value]} : {}
    end

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

    def check_bit_true(bit_position)
      min_bit_value = "1"
      if bit_position > 1
        (bit_position - 1).times {min_bit_value << "0"}
      end
      self.flags.to_i >= min_bit_value.to_i(2) && self.flags.to_i.to_s(2)[-bit_position].chr == "1"
    end

  end
end
