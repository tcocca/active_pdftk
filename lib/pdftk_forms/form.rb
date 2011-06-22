module PdftkForms
  # Represents a fillable form on a particular PDF.
  # It should be your preferred abstraction layer, for editable form content
  # Use a PdftkForms::Form object as an electronic document, read, edit & save it!
  #
  # @example
  #   bic = PdftkForms::Form.new('bic.pdf')
  #   bic.field_mapping_fill!
  #   bic.save
  #
  class Form
    
    # @return [String, File, Tempfile, StringIO] return the given PDF template.
    attr_reader :template

    # Create a new Form object based on the given template pdf file.
    #
    # @param [String, File, Tempfile, StringIO] template is the file on which the form is based.
    # @param [Hash] wrapper_statements is a hash containing default statements for the wrapper.
    #
    # @return [Form]
    #
    # @example
    #   bic = PdftkForms::Form.new(template, {:path => 'pdftk_path'})
    #   bic = PdftkForms::Form.new('bic.pdf')
    def initialize(template, wrapper_statements = {})
      @pdftk = Wrapper.new(wrapper_statements)
      @template = template
    end

    # Access all +Field+ objects associated to +self+.
    # fields are lazily loaded from the pdf file.
    #
    # @return [Array] return an array of Field objects
    #
    # @example
    #   bic.fields #=> [#<PdftkForms::Field:0x... >, #<PdftkForms::Field:0x... >, ...]
    def fields
      @fields ||= begin
        field_output = @pdftk.dump_data_fields(@template)
        raw_fields = field_output.string.split(/^---\n/).reject {|text| text.empty? }
        raw_fields.map do |field_text|
          attributes = {}
          field_text.scan(/^(\w+): (.*)$/) do |key, value|
            if key == "FieldStateOption"
              attributes[key] ||= []
              attributes[key] << value
            else
              attributes[key] = value
            end
          end
          Field.new(attributes)
        end
      end
    end

    # Get a Field given his 'name'.
    # Fields can also be accessed directly by their name (last example).
    # @param [String] field_name is the name of the field to retrieve.
    #
    # @return [Field, nil] return nil if the field_name doesn't exists.
    #
    # @example
    #   bic.get('first_field') #=> #<PdftkForms::Field:0x... >
    #   bic.get('not_a_field') #=> nil
    #   bic.first_field #=> #<PdftkForms::Field:0x... >
    def get(field_name)
      #TODO check if several inputs with same names are allowed
      fields.detect {|f| f.name == field_name.to_s}
    end

    # Set a Field value given his 'name'.
    # Fields can also be accessed directly by their name (last example).
    #
    # @param [String] field_name is the name of the field to retrieve.
    # @param [String] value is the to be set to the field.
    #
    # @return [false, String] value set to the field or false if field_name doesn't exists or is readonly.
    #
    # @example
    #   bic.set('first_field', 'SomeString') #=> 'SomeString'
    #   bic.set('not_a_field', 'SomeString') #=> false
    #   bic.first_field = 'SomeString' #=> 'SomeString'
    def set(field_name, value)
      f = get(field_name)
      (f.nil? || f.read_only?) ? false : f.value = value
    end

    # Save +self+ to a new pdf file.
    # if no output is given (or nil), the pdf will be saved in the same directory of the template
    # but extension will be changed from '.pdf' to '_filled.pdf'.
    #
    # @param [String, File, Tempfile, StringIO, nil] output where the PDF should be saved.
    # @param [Hash] options to apply to the output.

    # @return [String, File, Tempfile, StringIO, nil] Corresponding to the output argument, or false if the command fails but no error is raised.
    #
    # @example
    #   bic.set(..., ...) #=> ...
    #   bic.save #=> 'bic_filled.pdf'
    #   bic.save('bic.custom.pdf') #=> 'bic.custom.pdf'
    def save(output = nil, options = {})
      output = @template.split('.pdf').first + '_filled.pdf' if output.nil?
      @pdftk.fill_form(@template, to_h, options.merge(:output => output))
      output
    end

    # Save +self+ to the current PDF file
    #
    # @param [Hash] options to apply to the output.

    # @return [String, File, Tempfile, StringIO, nil] return the modified template.
    #
    # @example
    #   bic = PdftkForms::Form.new('bic.pdf')
    #   bic.save! #=> 'bic.pdf'
    def save!(options = {})
      save(@template, options)
    end

    # Create the fdf file corresponding to the current state of +self+.
    #
    # @param [Boolean] all_fields if it should return all fields, even empty one.
    #
    # @return [Fdf]
    #
    # @example
    #   bic.to_fdf #=> #<PdftkForms::Fdf:0x... >
    #   bic.to_fdf(true) #=> #<PdftkForms::Fdf:0x... >
    def to_fdf(all_fields = false)
      Fdf.new(to_h(all_fields))
    end

    # Create the xfdf file corresponding to the current state of +self+.
    #
    # @param [Boolean] all_fields if it should return all fields, even empty one.
    #
    # @return [Xfdf]
    #
    # @example
    #   bic.to_xfdf #=> #<PdftkForms::Xfdf:0x... >
    #   bic.to_xfdf(true) #=> #<PdftkForms::Xfdf:0x... >
    def to_xfdf(all_fields = false)
      Xfdf.new(to_h(all_fields))
    end

    # Fill the form values with fields names.
    #
    # Could be helpfull for autogenerated forms which are not mnemonic compliant.
    # @return +self+
    #
    # @note Only fills Text fields (will respect the default value for Choice or Button fields)
    #
    # @example
    #   bic.field_mapping_fill! #=> #<PdftkForms::Form:0x... >
    #
    def field_mapping_fill!
      fields.each { |f| f.value = f.name.to_s if f.type == 'Text'}
      self
    end

    # Return a hash representing the fields embedded in the file.
    #
    # @param [Boolean] all_fields if it should return all fields, even empty one.
    #
    # @return [Hash] hash where keys are field name (as string) and values are corresponding value
    #
    # @example
    #   bic.to_h #=> {'field1' => 'one', 'field2' => 'two'}
    #   bic.to_h(true) #=> {'field1' => 'one', 'field2' => 'two', 'field3' => ''}
    def to_h(all_fields = false)
      hash = {}
      fields.each do |f|
        next if f.no_export?
        hash[f.name.to_s] = f.value.to_s if (all_fields || f.value)
      end
      hash
    end

    def respond_to?(method_name, include_private = false)
      field_name = method_name.to_s.delete('=')
      fields.any? {|f| f.name == field_name} ? true : super
    end

    private

    def method_missing(method_name, *args)
      field_name = method_name.to_s.delete('=')
      if fields.any? {|f| f.name == field_name}
        method_name.to_s =~ /=/ ?  set(field_name, *args) : get(field_name)
      else
        super
      end
    end
  end
end

