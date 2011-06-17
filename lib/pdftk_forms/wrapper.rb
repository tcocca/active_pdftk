require 'tempfile'

module PdftkForms
  # Wraps calls to PdfTk
  class Wrapper

    # PdftkForms::Wrapper.new(:path => '/usr/bin/pdftk', :encrypt => true, :encrypt_options => 'allow Printing')
    # Or
    # PdftkForms::Wrapper.new  #try to locate the library in the system, fallback on 'pdftk' in the users path
    def initialize(options = {})
      @call = Call.new(options)
    end

    def default_statements
      @call.default_statements
    end

    # Allowed by pdftk in order to apply some output options (flatten, compress), without changing the content of the file
    def nop(template, options = {})
      @call.pdftk(options.merge(:input => template, :operation => nil))
    end

    # generate_fdf('a.pdf') => will yield the FDF as a StringIO output
    # or to write the output to a file
    # generate_fdf('a.pdf', :output => 'out.pdf')
    def generate_fdf(template, options = {})
      @call.pdftk(options.merge(:input => template, :operation => :generate_fdf))
    end

    def cat(ranges = [], options = {})
      call_range_operation(:cat, ranges, options)
    end

    def shuffle(ranges = [], options = {})
      call_range_operation(:shuffle, ranges, options)
    end

    # burst('in1.pdf') to split the input into pages with the default filename format of 'pg_%04d.pdf' ( 'pg_0001.pdf', 'pg_0002.pdf' )
    # To change the filename format, pass a printf style format to :output, ex:
    # burst('in1.pdf', :output => 'page_%02d.pdf') will burst pages in the format of 'page_01.pdf', 'page_02.pdf'
    def burst(template, options = {})
      @call.pdftk(options.merge(:input => template, :operation => :burst))
    end

    # background('in1.pdf', 'bg.pdf') for StringIO output
    # background('in1.pdf', 'bg.pdf', :output => 'out.pdf') to generate a pdf output
    # For multibackground pass :multi => true in the options, ex:
    # background('in1.pdf', 'bg.pdf', :muli => true)
    def background(template, background, options = {})
      call_multi_operation("background", template, background, options)
    end

    # stamp('in1.pdf', 'stamp.pdf') for StringIO output
    # stamp('in1.pdf', 'stamp.pdf', :output => 'out.pdf') to generate a pdf output
    # For multistamp pass :multi => true in the options, ex:
    # stamp('in1.pdf', 'stamp.pdf', :muli => true)
    def stamp(template, stamp, options = {})
      call_multi_operation("stamp", template, stamp, options)
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

    private

    def call_range_operation(operation, ranges, options)
      inputs = {}
      ranges.each do |range|
        if range[:pdf]
          if !inputs.has_key?(range[:pdf]) || (inputs[range[:pdf]].nil? && !range[:pass].nil?)
            inputs[range[:pdf]] = range[:pass]
            range.delete(:pass)
          end
        end
      end
      command_options = {:input => inputs, :operation => {operation => ranges}}
      @call.pdftk(options.merge(command_options))
    end

    def call_multi_operation(command, template, overlay, options)
      multi = options.delete(:multi)
      cmd = multi == true ? "multi#{command}".to_sym : command.to_sym
      @call.pdftk(options.merge(:input => template, :operation => {cmd => overlay}))
    end

  end
end
