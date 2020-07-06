require "open3"
require "tmpdir"

module ActivePdftk
  # Error that is raised when +pdftk+ could not be located on the system and the path to the library is not passed in
  class MissingLibrary < StandardError
    # Calls super with the message and a link to pdftk
    def initialize
      super("Pdftk library not found on your system, please check the binary path or fetch it at http://www.pdflabs.com/tools/pdftk-the-pdf-toolkit/")
    end
  end

  # Error that is raised when pdftk CLI returns an error
  class CommandError < StandardError
    # Return the text of +stderr+ and the command that was attempted
    def initialize(args = {})
      super("#{args[:stderr]} #!# While executing #=> `#{args[:cmd]}`")
    end
  end

  # Error that is raised when you attempt to pass streaming input for more than 1 file
  class MultipleInputStream < ArgumentError
    # Call super with the error message
    def initialize
      super("Only one input stream is allowed (other one should be a real path to a file.)")
    end
  end

  # Error that is raised when an illegal option was passed in
  class IllegalStatement < ArgumentError
    # Display the bad option and the list of valid options
    def initialize(args = {})
      super("`#{args[:statement].inspect}` is not a valid statement.\nShould be one of #{args[:options].inspect}.")
    end
  end

  # Error that is raise when you are trying to run commands with invalid options
  class InvalidOptions < StandardError
    # Raise the error and display the command that was attempted
    def initialize(args = {})
      super("Invalid options passed to the command, `#{args[:cmd]}`, please see `$: pdftk --help`")
    end
  end

  # Error that is raised when you specify a filename on a range option (cat|shuffle) and the file is not in the input list
  class MissingInput < StandardError
    # Raise an error with the missing file name if known, otherwise raise a standard error
    def initialize(args = {})
      unless args[:input].nil?
        super("Missing Input file, `#{args[:input]}`")
      else
        super("Missing Input files")
      end
    end
  end

  # Low level pdftk runner, it aims to handle all features provided by pdftk.
  # It is really easy to run a command. First create an instance,
  # it will locate your pdftk binary (except on Windows for now).
  #   call = Call.new(dsl_hash)
  # here, +dsl_hash+ is default options for this Call instance, one of them could be the path to the pdftk binary.
  #
  # And then we can run any command, it return the output file or +nil+.
  #   output = call.pdftk(dsl_hash)
  # ==From here, we will digg in the DSL (Domain-specific language) :
  #
  # As you know command line programs take often a bunch of arguments, in a very specific syntax. that is our case.
  # In order to call pdftk in a easy way, we build a DSL, it has a hash patern, with four keys : input, operation, output, options.
  # an additional key +:path+ can be set to specify the path to the pdftk binary.
  #   :input => some_input, :operation => some_operation, :output => some_output, :options => some_options
  #
  # ===Input
  #   :input => 'path/to/file.pdf'
  #   :input => {'path/to/file.pdf' => 'password'} # if the file needs a password
  # Some operations allow you to have several input files (as +:cat+ or +:shuffle+), in this case, you will give a hash with several files as keys :
  #   :input => {'a.pdf' => 'password', 'b.pdf' => nil} # if a file doesn't need any password, just pass +nil+.
  # If you want to pass in input stream it is quite easy too !
  #   :input => File.new # could also be a +StringIO+ or a +Tempfile+
  #
  # ===Operation
  # Now we want to choose one of the operation allowed by pdftk, to apply it on the set input(s) the general syntax is :
  #   :operation => {:some_operation => operation_argument}
  #   # or
  #   :operation => 'some_operation'
  # if you do not need to give any argument for the operation, just use the second form (note that strings and symbols are allowed).
  # All operation supported by pdftk should be supported here, for now, some are not _fully_ supported (contribution highly accepted) :
  #   nil => nil                                  # no operation.
  #   :cat => [Hash/Range]                                  # *.pdf wildcards not supported for now, also blank options for full file cat not supported (must pass :pdf inputs)
  #   :shuffle => [Hash/Range]                              # *.pdf wildcards not supported for now, also blank options for full file cat not supported (must pass :pdf inputs)
  #   :burst => nil
  #   :generate_fdf => nil
  #   :fill_form => String || File || StringIO || Tempfile
  #   :background => String || File || StringIO || Tempfile
  #   :multibackground => String || File || StringIO || Tempfile
  #   :stamp => String || File || StringIO || Tempfile
  #   :multistamp => String || File || StringIO || Tempfile
  #   :dump_data => nil
  #   :dump_data_utf8 => nil
  #   :dump_data_fields => nil
  #   :dump_data_fields_utf8 => nil
  #   :update_info => String || File || StringIO || Tempfile
  #   :update_info_utf8 => String || File || StringIO || Tempfile
  #   :attach_files => [String, String, ...]            # to_page is not supported for now
  #   :unpack_files => nil
  # +nil+ means no argument are expected (you should use the second form).
  # +String || File || StringIO || Tempfile+ any of these input objects is expected (as for :input).
  # +[...]+ an array of something is expected.
  # +[Hash/Range]+ are array of ranges written as hashes (?!). better check an example !
  #   [
  #   {:start => 1, :end => 'end', :pdf => 'a.pdf'},
  #   {:pdf => 'b.pdf', :start => 12, :end => 16, :orientation => 'E', :pages => 'even'}
  #   ]
  # Don't forget to provide the same filenames in the :input part (I know it is boring, but the wrapper, make it easier)
  # @note As inputs can use a +path_to_files+ or +stdin+ data stream, you should take care to have only one input data stream in a single command, otherwise a +MultipleInputStream+ exception will be raised.
  #
  # ===Output
  # it could be any of +NilClass || String || File || StringIO || Tempfile+
  # if no output is specified (or set to nil), the result will be routed to stdout and returned by the +pdftk+ method.
  #   :output => nil
  #   :output => 'path/to/target.pdf
  #   :output => StringIO.new
  #
  # ===Options
  # Options can be given by a hash of one or several of possibilities below :
  #   :owner_pw => String
  #   :user_pw => String
  #   :encrypt  => :'40bit' || :'128bit'
  #   :flatten  => true || false
  #   :compress  => true || false
  #   :keep_id  => :first || :final
  #   :drop_xfa  => true || false
  #   :allow  => ['Printing', 'DegradedPrinting', 'ModifyContents', 'Assembly', 'CopyContents', 'ScreenReaders', 'ModifyAnnotations', 'FillIn', 'AllFeatures']
  #
  class Call

    # @return [Hash] the default DSL statements.
    attr_reader :default_statements

    # Create an instance based upon the default provided DSL statements.
    #
    # @param [Hash] dsl_statements default statements as defined in DSL.
    # @option dsl_statements [String] :path (optional) the full path of the pdftk binary
    # @option dsl_statements [String, Hash, File, StringIO, Tempfile] :input the input part of the Hash
    # @option dsl_statements [String, Symbol, Hash] :operation the operation part of the Hash
    # @option dsl_statements [String, File, StringIO, Tempfile, nil] :output the output part of the Hash
    # @option dsl_statements [Hash] :options the input part of the Hash
    #
    # @raise +MissingLibrary+ if pdtk cannot be found and +:path+ is empty
    #
    # @example
    #  @call = PdftkFoms::Call.new  # no default statement, library path is automatically located.
    #  @call = PdftkFoms::Call.new(
    #    :path => '/usr/bin/pdftk',
    #    :operation => {:fill_form => 'a.fdf'},
    #    :options => { :flatten => false, :owner_pw => 'bar', :user_pw => 'baz', :encrypt  => :'40bit'})
    #
    def initialize(dsl_statements = {})
      @default_statements = dsl_statements
      @default_statements[:path] ||= locate_pdftk || "pdftk"
      raise MissingLibrary if pdftk_version.to_f == 0
    end

    # Process an operation with the given DSL statements
    #
    # @param [Hash] dsl_statements statements as defined in DSL.
    # @option dsl_statements [String] :path (optional) the full path of the pdftk binary
    # @option dsl_statements [String, Hash, File, StringIO, Tempfile] :input the input part of the Hash
    # @option dsl_statements [String, Symbol, Hash] :operation the operation part of the Hash
    # @option dsl_statements [String, File, StringIO, Tempfile, nil] :output the output part of the Hash
    # @option dsl_statements [Hash] :options the input part of the Hash
    #
    # @return resource specified in :output, if :ouput is not provided (or nil), return content of stdout in a StringIO, except for operation burst & unpack where Dir.temp is returned
    #
    # @example
    #   @call.pdftk(
    #    :input => {'a.pdf' => 'foo', 'b.pdf' => 'bar', 'c.pdf' => nil},
    #    :operation => {:fill_form => 'a.fdf'},
    #    :output => 'out.pdf',
    #    :options => {:flatten => true, :owner_pw => 'bar', :user_pw => 'baz', :encrypt  => :'40bit'})
    #
    # @raise +CommandError+ if pdftk return an error
    #
    def pdftk(dsl_statements = {})
      dsl_statements = @default_statements.merge(dsl_statements)
      cmd = "#{@default_statements[:path]} #{set_cmd(dsl_statements)}"
      if dsl_statements[:operation].to_s.match(/burst|unpack_files/)
        cmd.insert(0, "cd #{Dir.tmpdir} && ")
      end
      Open3.popen3(cmd) do |stdin, stdout, stderr|
        if @input
          @input.rewind
          stdin.puts @input.read
        end
        stdin.close
        @output.puts stdout.read if @output && !@output.is_a?(String)
        # We ignore 'no info dictionary' warning since it doesn't affect the integrity of the PDF
        # and handling this warning as an error prevents us from accessing the other metadata
        raise(CommandError, {:stderr => @error, :cmd => cmd, :stdout => stdout, :output => @output}) unless
          ((@error = stderr.read).empty? || @error.include?("Warning: no info dictionary found"))
      end
      if dsl_statements[:operation].to_s.match(/burst|unpack_files/) && dsl_statements[:output].nil?
        Dir.tmpdir
      else
        @output
      end
    end

    # this hash represent order of parts in the command line.
    PDFTK_ORDER = [:input, :operation, :output, :options]

    # this hash represent the mapping between pdftk CLI syntax and our DSL.
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

    # Prepare the command line string
    #
    # @param [Hash] dsl_statements statements as defined in DSL.
    # @option dsl_statements [String, Hash, File, StringIO, Tempfile] :input the input part of the Hash
    # @option dsl_statements [String, Symbol, Hash] :operation the operation part of the Hash
    # @option dsl_statements [String, File, StringIO, Tempfile, nil] :output the output part of the Hash
    # @option dsl_statements [Hash] :options the input part of the Hash
    #
    # @return [String]
    #
    # @example
    #   @call.set_cmd(
    #    :input => { 'a.pdf' => 'foo', 'b.pdf' => 'bar', 'c.pdf' => nil},
    #    :operation => {:fill_form => 'a.fdf'},
    #    :output => 'out.pdf',
    #    :options => {:flatten => true, :owner_pw => 'bar', :user_pw => 'baz', :encrypt  => :'40bit'})
    #   #=> "B=c.pdf C=a.pdf D=b.pdf input_pw C=foo D=bar fill_form a.fdf output out.pdf flatten encrypt_40bit owner_pw bar user_pw baz"
    #
    def set_cmd(dsl_statements = {})
      @input, @output, @error, @input_file_map = nil, nil, nil, nil
      dsl_statements = @default_statements.merge(dsl_statements)
      PDFTK_ORDER.collect do |part|
        case part
          when :input then build_input(dsl_statements[part])
          when :operation then build_operation(PDFTK_MAPPING[part], dsl_statements[part])
          when :output then build_output(dsl_statements[part])
          when :options then build_options(PDFTK_MAPPING[part], dsl_statements[part])
        end
      end.flatten.compact.join(' ').squeeze(' ').strip
      #TODO check if Array#shelljoin will do a better job.
    end

    # Check if xfdf is supported by the current pdftk library
    #
    # @return [Boolean]
    #
    def xfdf_support?
      pdftk_version.to_f >= 1.40
    end

    # Check if utf8 is supported by the current pdftk library
    #
    # @return [Boolean]
    #
    def utf8_support?
      pdftk_version.to_f >= 1.44
    end

    # Return the version number (as a string) of the current pdftk library
    #
    # @return [String]
    #
    def pdftk_version
      %x{#{@default_statements[:path]} --version 2>&1}.scan(/pdftk (\S*) a Handy Tool/).join
    end

    # Return the path of the pdftk library if it can be located.
    #
    # @return [String, nil] return nil if the library cannot be found on the system
    #
    # @note Should work on all unix systems (Linux, Mac Os X)
    #
    def self.locate_pdftk
      @pdftk_location ||= begin
        auto_path = %x{locate pdftk | grep "/bin/pdftk"}.strip.split("\n").first
        #TODO find a valid Win32 procedure (not in my top priorities)
        (auto_path.nil? || auto_path.empty?) ? nil : auto_path
      end
    end

    def locate_pdftk
      self.class.locate_pdftk
    end

    private

    # Prepare the input part of the command line string
    #
    # @param [Hash, String, File, Tempfile, StringIO] as defined in DSL, input statements only.
    #
    # @return [String]
    #
    # @raise +MultipleInputStream+ if several input stream are set
    #
    # @example
    #   build_input(StringIO.new) #=> "-"
    #   build_input('a.pdf' => 'foo', 'b.pdf' => 'bar', 'c.pdf' => nil) #=> "B=c.pdf C=a.pdf D=b.pdf input_pw C=foo D=bar"
    #
    def build_input(args)
      out, i = [[], "input_pw",[]], "A"
      case args
      when Hash
        @input_file_map = {}
        args.each do |file, pass|
          out.first << "#{i}=\"#{file}\""
          out.last << "#{i}=#{pass}" if pass
          @input_file_map[file] = "#{i}"
          i.next!
        end
      when String
        out.first << args
      when File, Tempfile, StringIO
        out.first << "-"
        @input ? raise(MultipleInputStream) : (@input = args)
      end
      (out.last.empty? ? out.first : out.flatten).join(' ')
    end

    # Prepare the operation part of the command line string
    #
    # @param [Hash, String, Symbol] as defined in DSL, operation statements only.
    #
    # @raise +MultipleInputStream+ if several input stream are set
    # @raise +MissingInput+ if range ask for files not in +:input+ part
    # @raise +InvalidOptions+ Tom ! what it is ?
    #
    # @return [String]
    #
    # @example
    #   build_operation() #=> ""
    #
    def build_operation(*args)
      abilities = args.shift || {}
      operation = args.shift
      operation = {operation.to_sym => nil} if (operation.is_a?(String) || operation.is_a?(Symbol))
      operation = operation.to_a.flatten(1)
      check_statement(abilities, operation.first)
      @operation_name = operation.first
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

    # Prepare the output part of the command line string
    #
    # @param [String, Symbol, nil] as defined in DSL, operation statements only.
    #
    # @return [String]
    #
    # @example
    #   build_output(StringIO.new) #=> "output -"
    #   build_output(nil) #=> "output -"
    #   build_output('file.pdf') #=> "output file.pdf"
    #
    def build_output(value)
      case value
        when NilClass
          @output = StringIO.new
          unless [:burst, :unpack_files].include?(@operation_name)
            "output -"
          else
            ""
          end
        when String
          @output = value
          "output #{value}"
        when File, Tempfile, StringIO
          @output = value
          "output -"
      end
    end

    # Prepare the options part of the command line string
    #
    # @param [Hash] as defined in DSL, options statements only.
    #
    # @return [Array]
    #
    # @example
    #   build_options(:flatten => true, :owner_pw => 'bar', :user_pw => 'baz', :encrypt  => :'40bit') #=> ["flatten", "encrypt_40bit", "owner_pw bar", "user_pw baz"]
    #
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

    # Prepare the rage operation part of the command line string
    #
    # @param [Hash] as defined in DSL, rage operation statements only.
    #
    # @return [String]
    #
    # @example
    #   build_range_option(:pdf => 'a.pdf', :start => 1, :end => 'end', :pages => 'odd', :orientation => 'E') #=> "A1-endoddE"
    #
    def build_range_option(range_args)
      range = ""
      if range_args[:custom_range]
        #@todo validate range and account for multiple PDFs
        #@todo add tests to this
        range += range_args[:custom_range]
      else
        if range_args[:pdf] && !@input_file_map.nil?
          raise(MissingInput, {:input => range_args[:pdf]}) unless @input_file_map.has_key?(range_args[:pdf])
          range += @input_file_map[range_args[:pdf]]
        end
        range += range_args[:start].to_s if range_args[:start]
        if range_args[:end]
          range += "1" unless range_args[:start]
          range += "-#{range_args[:end]}"
        end
      end
      range += range_args[:pages] if range_args[:pages]
      range += range_args[:orientation] if range_args[:orientation]
      range
    end

    # Check for illegal statements in the hash
    #
    # @param [Hash, String, Symbol] statement operation or options provided in the dsl_hash.
    # @param [Hash, String, Symbol] abilities as defined in DSL, operation statements only.
    #
    # @raise +IllegalStatement+ for the found illegal statement
    #
    def check_statement(abilities, statement)
      raise(IllegalStatement, {:options => abilities.keys, :statement => statement}) unless abilities.keys.include?(statement ? statement.to_sym : nil)
    end

  end
end
