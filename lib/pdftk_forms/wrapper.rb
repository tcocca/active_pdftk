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


#Here is a representation of a pdftk command
#command = {
#:input => {'a.pdf' => 'foo', 'b.pdf' => 'bar', 'c.pdf' => nil},
#:operation => {:fill_form => 'a.fdf'},
#:output => 'out.pdf',
#:flatten => true,
#:owner_pw => 'baz'
#}

    PDFTK_MAPPING = {
      :input => {
        :input_pw => 'input_pw',
      },
      :operation => {
        nil => nil,
#        :cat => Array of Range,                 # Array of ranges [ < page ranges > ]
#        :shuffle => Array of Range,             # Array of ranges [<page ranges>]
#        :burst => nil,
#        :generate_fdf => nil,
        :fill_form => 'fill_form',                   #< FDF data filename | XFDF data filename | - | PROMPT >
#        :background => String,                   #< background PDF filename | - | PROMPT >
#        :multibackground => String,              #< multibackground PDF filename | - | PROMPT >
#        :stamp => String,                        #< stamp PDF filename | - | PROMPT >
#        :multistamp => String,                   #< multistamp PDF filename | - | PROMPT >
#        :dump_data => nil,
#        :dump_data_utf8 => nil,
        :dump_data_fields => nil,
        :dump_data_fields_utf8 => nil,
#        :update_info => String,                  #< info data filename | - | PROMPT >
#        :update_info_utf8 => String,             #< info data filename | - | PROMPT>
#        :attach_files => Array of String,        #< attachment filenames | PROMPT > [ to_page < page number | PROMPT > ]
#        :unpack_files => nil
      },
      :output => {
        :owner_pw => 'owner_pw',
        :user_pw => 'user_pw',
        :encrypt  => {:'40bit' => 'encrypt_40bit', :'128bit' => 'encrypt_128bit'},
        :flatten  => {true => 'flatten', false => nil},
        :compress  => {true => 'compress', false => 'uncompress'},
        :keep_id  => {:first => 'keep_first_id', :final => 'keep_final_id'},
        :drop_xfa  => {true => 'drop_xfa', false => nil},
        :allow  => ['Printing', 'DegradedPrinting', 'ModifyContents', 'Assembly', 'CopyContents', 'ScreenReaders', 'ModifyAnnotations', 'FillIn', 'AllFeatures']
      }
    }

    def pdftk (options = {})
      call_pdftk set_cmd(options)
    end

    def call_pdftk(*args)
      %x{#{path} #{args.flatten.compact.join ' '}}
    end

    # {:input => {'a.pdf' => 'foo', 'b.pdf' => 'bar', 'c.pdf' => nil},
    # :operation => {:fill_form => 'a.fdf'},
    # :output => {'out.pdf' => {:flatten => true, :owner_pw => 'bar', :user_pw => 'baz', :encrypt  => :'40bit'}}}
    # #=> ["B=c.pdf C=a.pdf D=b.pdf input_pw C=foo D=bar", ["fill_form a.fdf"], ["output", "out.pdf", ["flatten", "encrypt_40bit", "owner_pw bar", "user_pw baz"]]]

    def set_cmd(options = {})
      [
      build_input(options[:input]),
      build_options(PDFTK_MAPPING[:operation], options[:operation]),
      ['output', options[:output].keys.first] << build_options(PDFTK_MAPPING[:output], options[:output].values.first)
      ]
    end

    # {'a.pdf' => 'foo', 'b.pdf' => 'bar', 'c.pdf' => nil} #=> "B=c.pdf C=a.pdf D=b.pdf input_pw C=foo D=bar"
    def build_input(options)
      out, i = [[], "input_pw",[]], "A"
      case options
      when Hash:
        options.each do |file, pass|
          out.first << "#{i.next!}=#{file}"
          out.last << "#{i}=#{pass}" if pass
        end
      when String:
        out.first << options
      end
      (out.last.empty? ? out.first : out.flatten).join(' ')
    end

    # {:flatten => true, :owner_pw => 'bar', :user_pw => 'baz', :encrypt  => :'40bit'}} #=> ["flatten", "encrypt_40bit", "owner_pw bar", "user_pw baz"]
    # OR
    # {:fill_form => 'a.fdf'} #=> ["fill_form a.fdf"]
    def build_options(*args)
      abilities = args.shift || {}
      options = args.shift || {}
      @options.merge(options).collect do |option, value|
        current = abilities[option.to_sym]
        case current
          when String:  "#{current} #{value}"
          when Hash:    "#{current[value]}"
          when Array:   "#{option} #{current.collect{|i| i.to_s.downcase} && value.collect{|i| i.to_s.downcase}.join(' ')}"
        end
      end
    end

  end
end

