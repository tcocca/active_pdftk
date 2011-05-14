require "open3"

module PdftkForms
  class CommandError < StandardError
    def initialize(args = {})
      super("#{args[:stderr]} #!# While executing #=> `#{args[:cmd]}`")
    end
  end
  class MultipleInputStream < ArgumentError
    def initialize
      super("Only one input stream is allowed (other one should be a real path to a file.)")
    end
  end
  class IllegalStatement < ArgumentError
    def initialize(args = {})
      super("`#{args[:statement].inspect}` is not a valid statement.\nShould be one of #{args[:options].inspect}.")
    end
  end

  # Build pdftk command
  class Call
    attr_reader :path, :default_statements
    
    # PdftkFoms::Call.new  # assumes 'pdftk' is in the users path, no default statement
    # Or
    # PdftkFoms::Call.new(:path => '/usr/bin/pdftk', :operation => {:fill_form => 'a.fdf'}, :options => { :flatten => false, :owner_pw => 'bar', :user_pw => 'baz', :encrypt  => :'40bit'})
    def initialize(options = {})
      @path = options.delete(:path) || "pdftk"
      @default_statements = options
    end

    # Here is a representation of a pdftk command
    # {
    # :input => {'a.pdf' => 'foo', 'b.pdf' => 'bar', 'c.pdf' => nil},
    # :operation => {:fill_form => 'a.fdf'},
    # :output => 'out.pdf',
    # :options => {:flatten => true, :owner_pw => 'bar', :user_pw => 'baz', :encrypt  => :'40bit'}
    # }
    def pdftk(options = {})
      cmd = "#{path} #{set_cmd(options)}"
      Open3.popen3(cmd) do |stdin, stdout, stderr|
        stdin.puts @input.read if @input
        stdin.close
        @output.puts stdout.read if @output
        raise(CommandError, {:stderr => @error, :cmd => cmd}) unless (@error = stderr.read).empty?
      end
      @output ? @output : true
    end

    # See http://www.pdflabs.com/tools/pdftk-the-pdf-toolkit/ for a full manual.
    # this hash represent the mapping between pdftk CLI syntax and our DSL.
    #
    PDFTK_ORDER = [:input, :operation, :output, :options]
    PDFTK_MAPPING = {
      :operation => {
        nil => nil,                              # no operation.
#        :cat => Array of Range,                 # Array of ranges [ < page ranges > ]
#        :shuffle => Array of Range,             # Array of ranges [<page ranges>]
        :burst => nil,                           # for 'burst' operation output could be something line 'page_%02d.pdf'
        :generate_fdf => nil,
        :fill_form => '',                        #< FDF data filename | XFDF data filename | - | PROMPT >
        :background => '',                       #< background PDF filename | - | PROMPT >
        :multibackground => '',                  #< multibackground PDF filename | - | PROMPT >
        :stamp => '',                            #< stamp PDF filename | - | PROMPT >
        :multistamp => '',                       #< multistamp PDF filename | - | PROMPT >
        :dump_data => nil,
        :dump_data_utf8 => nil,
        :dump_data_fields => nil,
        :dump_data_fields_utf8 => nil,
        :update_info => '',                      #< info data filename | - | PROMPT >
        :update_info_utf8 => '',                 #< info data filename | - | PROMPT>
        :attach_files => [],                      #< attachment filenames | PROMPT > [ to_page < page number | PROMPT > ] !to_page is not supported for now
        :unpack_files => nil
      },
      :options => {
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

    # {:input => {'a.pdf' => 'foo', 'b.pdf' => 'bar', 'c.pdf' => nil},
    # :operation => {:fill_form => 'a.fdf'},
    # :output => {'out.pdf' => {:flatten => true, :owner_pw => 'bar', :user_pw => 'baz', :encrypt  => :'40bit'}}}
    # #=> ["B=c.pdf C=a.pdf D=b.pdf input_pw C=foo D=bar", ["fill_form a.fdf"], ["output", "out.pdf", ["flatten", "encrypt_40bit", "owner_pw bar", "user_pw baz"]]]
    #
    def set_cmd(options = {})
      @input, @output, @error = nil, nil, nil
      options = @default_statements.merge(options)
      PDFTK_ORDER.collect do |part|
        case part
          when :input then build_input(options[part])
          when :operation then build_operation(PDFTK_MAPPING[part], options[part])
          when :output then build_output(options[part])
          when :options then build_options(PDFTK_MAPPING[part], options[part])
        end
      end.flatten.compact.join(' ').squeeze(' ').strip
    end

    protected

    # {'a.pdf' => 'foo', 'b.pdf' => 'bar', 'c.pdf' => nil} #=> "B=c.pdf C=a.pdf D=b.pdf input_pw C=foo D=bar"
    def build_input(args)
      out, i = [[], "input_pw",[]], "A"
      case args
      when Hash
        args.each do |file, pass|
          out.first << "#{i.next!}=#{file}"
          out.last << "#{i}=#{pass}" if pass
        end
      when String
        out.first << args
      when File, Tempfile, StringIO
        out.first << "-"
        @input ? raise(MultipleInputStream) : (@input = args)
      end
      (out.last.empty? ? out.first : out.flatten).join(' ')
    end

    def build_operation(*args)
      abilities = args.shift || {}
      operation = args.shift
      operation = {operation.to_sym => nil} if (operation.is_a?(String) || operation.is_a?(Symbol))
      operation = operation.to_a.flatten(1)
      check_statement(abilities, operation.first)
      case operation.last
      when NilClass
          "#{operation.first}"
      when String, Symbol
          "#{operation.first} #{operation.last}"
      when File, Tempfile, StringIO
          @input ? raise(MultipleInputStream) : (@input = operation.last)
          "#{operation.first} -"
      when Array
          "#{operation.first} #{operation.last.join(' ')}"
      end
    end

    def build_output(value)
      case value
        when NilClass
          @output = StringIO.new
          ""
        when String
          "output #{value}"
        when File, Tempfile, StringIO
          @output = value
          "output -"
      end
    end

    # {:flatten => true, :owner_pw => 'bar', :user_pw => 'baz', :encrypt  => :'40bit'}} #=> ["flatten", "encrypt_40bit", "owner_pw bar", "user_pw baz"]
    def build_options(*args)
      abilities = args.shift || {}
      options = args.shift || {}
      options.collect do |option, value|
        check_statement(abilities, option)
        case current = abilities[option.to_sym]
        when String
          "#{current} #{value}"
        when Hash
          "#{current[value]}"
        when Array
          "#{option} #{current.collect{|i| i.to_s.downcase} && value.collect{|i| i.to_s.downcase}.join(' ')}"
        end
      end
    end

    def check_statement(abilities, statement)
      raise(IllegalStatement, {:options => abilities.keys, :statement => statement}) unless abilities.keys.include?(statement ? statement.to_sym : nil)
    end

  end
end

