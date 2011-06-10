require 'tempfile'

module PdftkForms
  class NotImplemented < StandardError
    def initialize(method)
      super("Command Not Yet Implemented: #{method}")
    end
  end

  # Wraps calls to PdfTk
  class Wrapper

    # PdftkForms::Wrapper.new(:path => '/usr/bin/pdftk', :encrypt => true, :encrypt_options => 'allow Printing')
    # Or
    # PdftkForms::Wrapper.new  #try to locate the library in the system, fallback on 'pdftk' in the users path
    def initialize(options = {})
      @call = Call.new options
    end

    def default_statements
      @call.default_statements
    end

    # Allowed by pdftk in order to apply some output options (flatten, compress), without changing the content of the file
    def nop(template, options)
      @call.pdftk(options.merge(:input => template, :operation => nil))
    end

    def cat
      raise(NotImplemented, 'cat')
    end

    def shuffle
      raise(NotImplemented, 'shuffle')
    end

    def burst
      raise(NotImplemented, 'burst')
    end

    # should allow multiple
    def background
      raise(NotImplemented, 'background')
    end

    # should allow multiple
    def stamp
      raise(NotImplemented, 'stamp')
    end

    def dump_data_fields(template)
      cmd = @call.utf8_support? ? :dump_data_fields_utf8 : :dump_data_fields
      field_output = @call.pdftk(:input => template, :operation => cmd)
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
    
    def fill_form(template, data = {}, options ={})
      input = @call.xfdf_support? ? Xfdf.new(data) : Fdf.new(data)
      @call.pdftk(options.merge(:input => template, :operation => {:fill_form => StringIO.new(input.to_s)}))
    end

    def dump_data(template)
      cmd = @call.utf8_support? ? :dump_data_utf8 : :dump_data
      @call.pdftk(:input => template, :operation => cmd)
    end

    def update_info(template, infos, options = {})
      cmd = @call.utf8_support? ? :update_info_utf8 : :update_info
      @call.pdftk(options.merge(:input => template, :operation => {cmd => infos}))
    end

    def attach_files(template, files, options = {})
      @call.pdftk(options.merge(:input => template, :operation => {:attach_files => files}))
    end

    def unpack_files(template, directory)
      @call.pdftk(:input => template, :operation => :unpack_files, :output => directory)
    end
  end
end
