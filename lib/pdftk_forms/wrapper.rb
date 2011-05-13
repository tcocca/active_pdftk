require 'tempfile'
module PdftkForms
  # Wraps calls to PdfTk
  class Wrapper

    attr_reader :path, :options

    # PdftkWrapper.new('/usr/bin/pdftk', :encrypt => true, :encrypt_options => 'allow Printing')
    # Or
    # PdftkWrapper.new  #assumes 'pdftk' is in the users path
    def initialize(pdftk_path = nil, options = {})
      @path = pdftk_path || "pdftk"
      @options = options
    end

    # pdftk.fill_form('/path/to/form.pdf', '/path/to/destination.pdf', :field1 => 'value 1')
    # if your version of pdftk does not support xfdf then call
    # pdftk.fill_form('/path/to/form.pdf', '/path/to/destination.pdf', {:field1 => 'value 1'}, false)
    def fill_form(template, destination, *args)
      data = args.shift || {}
      options = args.shift || {}
      input = true ? Xfdf.new(data) : Fdf.new(data) # hacked because does'nt exist anymore
      tmp = Tempfile.new('pdf_forms_input')
      tmp.close
      input.save_to tmp.path
      call_pdftk template, 'fill_form', tmp.path, 'output', destination, build_options(options)
      tmp.unlink
    end

    def fields(template_path)
      unless @all_fields
        field_output = call_pdftk(template_path, 'dump_data_fields')
        raw_fields = field_output.split(/^---\n/).reject {|text| text.empty? }
        @all_fields = raw_fields.map do |field_text|
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
      @all_fields
    end

    protected

    def call_pdftk(*args)
      %x{#{path} #{args.flatten.compact.join ' '}}
    end
  end
end

