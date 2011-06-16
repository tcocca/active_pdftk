require "open3"

module PdftkForms
  class MissingLibrary < StandardError
    def initialize
      super("Pdftk library not found on your system, please check the binary path or fetch it at http://www.pdflabs.com/tools/pdftk-the-pdf-toolkit/")
    end
  end
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
  class InvalidOptions < StandardError
    def initialize(args = {})
      super("Invalid options passed to the command, `#{args[:cmd]}`, please see `$: pdftk --help`")
    end
  end
  class MissingInput < StandardError
    def initialize(args = {})
      unless args[:input].nil?
        super("Missing Input file, `#{args[:input]}`")
      else
        super("Missing Input files")
      end
    end
  end

  # Build pdftk command
  class Call
    attr_reader :default_statements
    
    # PdftkFoms::Call.new  # assumes 'pdftk' is in the users path, no default statement
    # Or
    # PdftkFoms::Call.new(:path => '/usr/bin/pdftk', :operation => {:fill_form => 'a.fdf'}, :options => { :flatten => false, :owner_pw => 'bar', :user_pw => 'baz', :encrypt  => :'40bit'})
    def initialize(options = {})
      @default_statements = options
      @default_statements[:path] ||= locate_pdftk || "pdftk"
      raise MissingLibrary if pdftk_version.to_f == 0
    end

    # Here is a representation of a pdftk command
    # {
    # :input => {'a.pdf' => 'foo', 'b.pdf' => 'bar', 'c.pdf' => nil},
    # :operation => {:fill_form => 'a.fdf'},
    # :output => 'out.pdf',
    # :options => {:flatten => true, :owner_pw => 'bar', :user_pw => 'baz', :encrypt  => :'40bit'}
    # }
    def pdftk(options = {})
      options = @default_statements.merge(options)
      cmd = "#{@default_statements[:path]} #{set_cmd(options)}"
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
        nil => nil,                     # no operation.
        :cat => [],                     # *.pdf wildcards not supported for now, also blank options for full file cat not supported (must pass :pdf inputs)
        :shuffle => [],                 # *.pdf wildcards not supported for now, also blank options for full file cat not supported (must pass :pdf inputs)
        :burst => nil,
        :generate_fdf => nil,
        :fill_form => '',
        :background => '',
        :multibackground => '',
        :stamp => '',
        :multistamp => '',
        :dump_data => nil,
        :dump_data_utf8 => nil,
        :dump_data_fields => nil,
        :dump_data_fields_utf8 => nil,
        :update_info => '',
        :update_info_utf8 => '',
        :attach_files => [],            # to_page is not supported for now
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
      @input, @output, @error, @input_file_map = nil, nil, nil, nil
      options = @default_statements.merge(options)
      PDFTK_ORDER.collect do |part|
        case part
          when :input then build_input(options[part])
          when :operation then build_operation(PDFTK_MAPPING[part], options[part])
          when :output then build_output(options[part])
          when :options then build_options(PDFTK_MAPPING[part], options[part])
        end
      end.flatten.compact.join(' ').squeeze(' ').strip
      #TODO if Array#shelljoin will do a better job
    end

    def xfdf_support?
      pdftk_version.to_f >= 1.40
    end

    def utf8_support?
      pdftk_version.to_f >= 1.44
    end

    def pdftk_version
      %x{#{@default_statements[:path]} --version 2>&1}.scan(/pdftk (\S*) a Handy Tool/).join
    end

    def locate_pdftk # Try to locate the library
      auto_path = %x{locate pdftk | grep "/bin/pdftk"}.strip.split("\n").first # should work on all *nix system
      #TODO find a valid Win32 procedure (not in my top priorities)
      auto_path.empty? ? nil : auto_path
    end

    protected

    # {'a.pdf' => 'foo', 'b.pdf' => 'bar', 'c.pdf' => nil} #=> "B=c.pdf C=a.pdf D=b.pdf input_pw C=foo D=bar"
    def build_input(args)
      out, i = [[], "input_pw",[]], "A"
      case args
      when Hash
        @input_file_map = {}
        args.each do |file, pass|
          out.first << "#{i.next!}=#{file}"
          out.last << "#{i}=#{pass}" if pass
          @input_file_map[file] = "#{i}"
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
      if [:cat, :shuffle].include?(operation.first)
        if operation.last.nil? || operation.last.empty? || !operation.last.is_a?(Array)
          raise(InvalidOptions, {:cmd => operation.first})
        elsif operation.last.collect{|h| h[:pdf]}.uniq.size > 1 && (@input_file_map.nil? || @input_file_map.empty?)
          raise MissingInput
        else
          ops = operation.last.collect {|range| build_range_option(range)}.join(' ')
          "#{operation.first} #{ops}"
        end
      else
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

    # {:pdf => 'a.pdf', :start => 1, :end => 'end', :pages => 'odd', :orientation => 'E'} # => 'A1-endoddE
    def build_range_option(range_args)
      range = ""
      if range_args[:pdf] && !@input_file_map.nil?
        raise(MissingInput, {:input => range_args[:pdf]}) unless @input_file_map.has_key?(range_args[:pdf])
        range += @input_file_map[range_args[:pdf]]
      end
      range += range_args[:start].to_s if range_args[:start]
      if range_args[:end]
        range += "1" unless range_args[:start]
        range += "-#{range_args[:end]}"
      end
      range += range_args[:pages] if range_args[:pages]
      range += range_args[:orientation] if range_args[:orientation]
      range
    end

    def check_statement(abilities, statement)
      raise(IllegalStatement, {:options => abilities.keys, :statement => statement}) unless abilities.keys.include?(statement ? statement.to_sym : nil)
    end

  end
end

