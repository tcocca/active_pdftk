module PdftkForms
  # Represents a fillable form on a particular PDF.
  # it is your prefered abstraction layer, all actions on a PDF could be triggered from here.
  # Use a PdftkForms::Form object as an electronic document, read, edit & save it!
  # @bic = PdftkForms::Form.new('bic.pdf')
  # @bic.field_mapping_fill!
  # @bic.save
  #
  class Form

    attr_reader :template

    # Create a new Form object based on the given template pdf file.
    #
    # @param [String, File, Tempfile, StringIO] template is the file which we will perform all operation.
    # if it is String it represent the path to access the file
    # other case are ruby object [File, Tempfile, StringIO] which contain a PDF file.
    # @param [Hash] wrapper_statements is a hash containing default statements for the wrapper (path of the library, output options, ...)
    #
    # @return [Form]
    #
    # @example
    # @bic = PdftkForms::Form.new(template, {:path => 'pdfxt_path'})
    # @bic = PdftkForms::Form.new('bic.pdf')
    #
    def initialize(template, wrapper_statements = {})
      @pdftk = Wrapper.new(wrapper_statements)
      @template = template
    end

    # Access all Field objects associated to +self+.
    # fields are lazily loaded from the pdf file.
    #
    # @return [Array]
    #
    # @example
    # @bic = PdftkForms::Form.new('bic.pdf')
    # @bic.fields #=> [#<PdftkForms::Field:0x... >, #<PdftkForms::Field:0x... >, ...]
    #
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

    # Get a Field by his 'field_name'.
    #
    # @param [String] field_name of the field to retrieve.
    #
    # @return [nil, Field]
    #
    # @example
    # @bic = PdftkForms::Form.new('bic.pdf')
    # @bic.get('filled_field') #=> #<PdftkForms::Field:0x... >
    # @bic.get('not_a_field') #=> nil
    #
    def get(field_name)
      #TODO check if several inputs with same names are allowed
      fields.detect {|f| f.name == field_name.to_s}
    end

    # Set a Field value by his 'field_name'.
    #
    # @param [String] field_name of the field to retrieve.
    # @param [String] value of set the field.
    #
    # @return [false, String]
    #
    # @example
    # @bic = PdftkForms::Form.new('bic.pdf')
    # @bic.set('filled_field', 'SomeString') #=> 'SomeString'
    # @bic.set('not_a_field', 'SomeString') #=> false
    # calling #set on a ReadOnly field will result in false as well
    #
    def set(field_name, value)
      f = get(field_name)
      (f.nil? || f.read_only?) ? false : f.value = value
    end

    # Save self to a new pdf file.
    #
    # @param [String, File, Tempfile, StringIO, nil] output where the PDF should be saved.
    # if no output is given (or nil), the pdf will be saved in the same directory of the template but extension will be changed from '.pdf' to '_filled.pdf'.
    # @param [Hash] options to apply to the output.

    # @return [String, File, Tempfile, StringIO, nil] Corresponding to the output argument, or false if the command fails but no error is raised.
    #
    # @example
    # @bic = PdftkForms::Form.new('bic.pdf')
    # @bic.set(..., ...) #=> ...
    # @bic.save #=> 'bic_filled.pdf'
    # @bic.save('bic.custom.pdf') #=> 'bic.custom.pdf'
    #
    def save(output = nil, options = {})
      output = @template.split('.pdf').first + '_filled.pdf' if output.nil?
      @pdftk.fill_form(@template, to_h, options.merge(:output => output))
      output
    end

    # Save self to the current PDF file
    #
    # @param [Hash] options to apply to the output.

    # @return [String, File, Tempfile, StringIO, nil] Corresponding to the current template
    #
    # @example
    # @bic = PdftkForms::Form.new('bic.pdf')
    # @bic.save! #=> 'bic.pdf'
    #
    def save!(options = {})
      save(@template, options)
    end

    # Create the fdf file corresponding to the state of +self+.
    #
    # @param [Boolean] full represent all fields (true) or only non empty one (false or default).
    #
    # @return [Fdf]
    #
    # @example
    # @bic = PdftkForms::Form.new('bic.pdf')
    # @bic.to_fdf #=> #<PdftkForms::Fdf:0x... >
    # @bic.to_fdf(true) #=> #<PdftkForms::Fdf:0x... >
    #
    def to_fdf(full = false)
      Fdf.new(to_h(full))
    end

    # Create the xfdf file corresponding to the state of +self+.
    #
    # @param [Boolean] full represent all fields (true) or only non empty one (false or default).
    #
    # @return [Xfdf]
    #
    # @example
    # @bic = PdftkForms::Form.new('bic.pdf')
    # @bic.to_xfdf #=> #<PdftkForms::Xfdf:0x... >
    # @bic.to_xfdf(true) #=> #<PdftkForms::Xfdf:0x... >
    #
    def to_xfdf(full = false)
      Xfdf.new(to_h(full))
    end

    # Fill the form values with fields name
    # Helpfull for autogenerated forms which are not mnemonic compliant.
    # return self, so the methods could be chained.
    # @return self
    #
    # Note: only fills Text type fields (will respect the default value for Choice or Button fields)
    #
    # @example
    # @bic.field_mapping_fill! #=> #<PdftkForms::Field:0x... >
    #
    def field_mapping_fill!
      fields.each { |f| f.value = f.name.to_s if f.type == 'Text'}
      self
    end

    # Return a hash representing the fields embedded in the file.
    #
    # @param [Boolean] full if the hash represent all fields (true) or only non empty one (false or default).
    #
    # @return [Hash]
    #
    # @example
    # @bic.to_h #=> {'field1' => 'one', 'field2' => 'two'}
    # @bic.to_h(true) #=> {'field1' => 'one', 'field2' => 'two', 'field3' => ''}
    #
    def to_h(full = false)
      hash = {}
      fields.each do |f|
        next if f.no_export?
        hash[f.name.to_s] = f.value.to_s if (full || f.value)
      end
      hash
    end


    # Fields can be accessed directly by their name.
    #
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

