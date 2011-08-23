require 'tempfile'

module ActivePdftk
  # Wraps calls to the ActivePdftk::Call class
  #
  # provides methods around every operation for pdftk to make constructing the call with options easier than working directly with the ActivePdftk::Call class
  class Wrapper

    # Instantiates a new instance of wrapper and passes through the options hash to an instance of ActivePdftk::Call
    #
    # The full set of options on Call is supported here
    # @macro [new] see_options
    #   @see ActivePdftk::Call#initialize ActivePdftk::Call#initialize for the options hash argument
    # @param [Hash] dsl_statements default statements of the DSL, sent to the +Call+ instance
    def initialize(dsl_statements = {})
      @call = Call.new(dsl_statements)
    end

    # Delegates the method to the @call object that was instantiated
    def default_statements
      @call.default_statements
    end

    # Delegated the method to the @call object
    def xfdf_support?
      @call.xfdf_support?
    end

    # Allowed by pdftk in order to apply some output options (flatten, compress), without changing the content of the file.
    # @param [String, File, Tempfile, StringIO] template is the file to operate.
    # @param [Hash] options is a hash containing statements for the wrapper.
    # @macro see_options
    # @note +:input+ in the options hash will be overwritten by +template+ and +:operation+ will be overwritten.
    # @return resource specified in +:output+, if +:output+ is not provided (or +nil+), return content of +stdout+ in a +StringIO+.
    # @example
    #   nop('a.pdf', :options => {:encrypt  => :'40bit'}) # will encrypt the input pdf
    def nop(template, options = {})
      @call.pdftk(options.merge(:input => template, :operation => nil))
    end

    # Generate the FDF output of the template file.
    # @param [String, File, Tempfile, StringIO] template is the file to operate.
    # @param [Hash] options is a hash containing statements for the wrapper.
    # @macro see_options
    # @note +:input+ in the options hash will be overwritten by +template+ and +:operation+ will be overwritten.
    # @return resource specified in +:output+, if +:output+ is not provided (or +nil+), return content of +stdout+ in a +StringIO+.
    # @example
    #   generate_fdf('a.pdf') # will yield the FDF as a StringIO output
    #   generate_fdf('a.pdf', :output => 'out.pdf') # will write the output to a file
    def generate_fdf(template, options = {})
      @call.pdftk(options.merge(:input => template, :operation => :generate_fdf))
    end

    # Combine multiple files/sections of files into a single file.
    # @param [Array<Hash>] ranges An array of hashes representing a range (see ranges Hash options below)
    # @param [Hash] options is a hash containing statements for the wrapper.
    # @option ranges [String, File, StringIO, Tempfile] :pdf optional unless multiple inputs are required the file to run the range on.
    # @option ranges [String] :pass optional, the password for the file.
    # @option ranges [String] :start optional, the first page number of a page range, can be +end+ for the last page of the pdf if you wish to reverse the pages, eg: +end-1+ or +end-6+.
    # @option ranges [String] :end optional, the end of a range of pages, can be +end+ for the last page of the pdf.
    # @option ranges [String] :pages optional, one of +even,odd+, leave off for all pages.
    # @option ranges [String] :orientation optional, orientation of the page, one of +N,E,S,W,L,R,D+.
    # @see ActivePdftk::Call#initialize ActivePdftk::Call#initialize for the options hash argument
    # @note +:input+ in the options hash will be overwritten by +template+ and +:operation+ will be overwritten.
    # @return resource specified in +:output+, if +:output+ is not provided (or +nil+), return content of +stdout+ in a +StringIO+.
    # @example
    #   cat([{:pdf => 'a.pdf', :pass => 'foo'}, {:pdf => 'b.pdf', :start => 1, :end => 'end', :orientation => 'N', :pages => 'even'}]) # will return +StringIO+ of a single PDF containing a.pdf and the even pages of b.pdf
    #   cat([{:pdf => 'a.pdf', :pass => 'foo'}, {:pdf => 'b.pdf', :start => 1, :end => 'end', :orientation => 'N', :pages => 'even'}], :output => 'c.pdf') # will write the same as above to c.pdf
    def cat(ranges = [], options = {})
      command_options = call_range_operation(:cat, ranges)
      @call.pdftk(options.merge(command_options))
    end

    # Combine multiple files/sections of files into a single file similar to cat except used for collating.
    # @param [Array<Hash>] ranges An array of hashes representing a range (see ranges Hash options below).
    # @param [Hash] options is a hash containing statements for the wrapper.
    # @option ranges [String, File, StringIO, Tempfile] :pdf optional unless multiple inputs are required the file to run the range on.
    # @option ranges [String] :pass optional, the password for the file.
    # @option ranges [String] :start optional, the first page number of a page range, can be +end+ for the last page of the pdf if you wish to reverse the pages, eg: +end-1+ or +end-6+.
    # @option ranges [String] :end optional, the end of a range of pages, can be +end+ for the last page of the pdf.
    # @option ranges [String] :pages optional, one of +even,odd+, leave off for all pages.
    # @option ranges [String] :orientation optional, orientation of the page, one of +N,E,S,W,L,R,D+.
    # @see ActivePdftk::Call#initialize ActivePdftk::Call#initialize for the options hash argument
    # @note +:input+ in the options hash will be overwritten by +template+ and +:operation+ will be overwritten.
    # @return resource specified in +:output+, if +:output+ is not provided (or +nil+), return content of +stdout+ in a +StringIO+
    # @example
    #   shuffle([{:pdf => 'a.pdf', :pass => 'foo'}, {:pdf => 'b.pdf', :start => 1, :end => 'end', :orientation => 'N', :pages => 'even'}]) # will return +StringIO+ of a single PDF containing a.pdf and the even pages of b.pdf collated instead of back to back
    #   shuffle([{:pdf => 'a.pdf', :pass => 'foo'}, {:pdf => 'b.pdf', :start => 1, :end => 'end', :orientation => 'N', :pages => 'even'}], :output => 'c.pdf') # will write the same as above to c.pdf
    def shuffle(ranges = [], options = {})
      command_options = call_range_operation(:shuffle, ranges)
      @call.pdftk(options.merge(command_options))
    end

    # Burst the file into separate files for each page.
    # @param [String, File, Tempfile, StringIO] template is the file on which to be burst.
    # @param [Hash] options is a hash containing statements for the wrapper.
    # @macro see_options
    # @note +:input+ in the options hash will be overwritten by +template+ and +:operation+ will be overwritten.
    # @return resource specified in +:output+, if +:output+ is not provided (or +nil+), return +Dir.tmpdir+.
    # @example
    #   burst('in1.pdf') # will split the input into pages with the default filename format of 'pg_%04d.pdf' ( 'pg_0001.pdf', 'pg_0002.pdf' )
    #   #To change the filename format, pass a printf style format to :output, ex:
    #   burst('in1.pdf', :output => 'page_%02d.pdf') # will burst pages in the format of 'page_01.pdf', 'page_02.pdf'
    def burst(template, options = {})
      @call.pdftk(options.merge(:input => template, :operation => :burst))
    end

    # Add a background/watermark image/file the template pdf.
    # @param [String, File, Tempfile, StringIO] template is the file on which the form is based.
    # @param [String] background the location of the file you wish to background onto the template file.
    # @param [Hash] options is a hash containing statements for the wrapper.
    # @macro see_options
    # @note +:input+ in the options hash will be overwritten by +template+ and +:operation+ will be overwritten.
    # @return resource specified in +:output+, if +:output+ is not provided (or +nil+), return content of +stdout+ in a +StringIO+.
    # @example
    #   background('in1.pdf', 'bg.pdf') # for StringIO output
    #   background('in1.pdf', 'bg.pdf', :output => 'out.pdf') # to generate a pdf output
    #   background('in1.pdf', 'bg.pdf', :muli => true) # For multibackground pass :multi => true in the options
    def background(template, background, options = {})
       command_options = call_multi_operation("background", template, background, options.delete(:multi))
       @call.pdftk(options.merge(command_options))
    end

    # Add a stamp/foreground image/file to the template pdf.
    # @param [String, File, Tempfile, StringIO] template is the file on which the form is based.
    # @param [String] stamp the location of the file you wish to stamp onto the template file.
    # @param [Hash] options is a hash containing statements for the wrapper.
    # @macro see_options
    # @note +:input+ in the options hash will be overwritten by +template+ and +:operation+ will be overwritten.
    # @return resource specified in +:output+, if +:output+ is not provided (or +nil+), return content of +stdout+ in a +StringIO+.
    # @example
    #   stamp('in1.pdf', 'stamp.pdf') # for StringIO output
    #   stamp('in1.pdf', 'stamp.pdf', :output => 'out.pdf') # to generate a pdf output
    #   stamp('in1.pdf', 'stamp.pdf', :muli => true) # For multistamp pass :multi => true in the options
    def stamp(template, stamp, options = {})
       command_options = call_multi_operation("stamp", template, stamp, options.delete(:multi))
       @call.pdftk(options.merge(command_options))
    end

    # Dump the field data info from the template file.
    # @param [String, File, Tempfile, StringIO] template is the file on which the form is based.
    # @param [Hash] options is a hash containing statements for the wrapper.
    # @macro see_options
    # @note +:input+ in the options hash will be overwritten by +template+ and +:operation+ will be overwritten.
    # @return resource specified in +:output+, if +:output+ is not provided (or +nil+), return content of +stdout+ in a +StringIO+.
    # @example
    #   dump_data_fields()
    #   dump_data_fields('~/Desktop/a.pdf') # returns StringIO of the output
    #   dump_data_fields('~/Desktop/a.pdf', :output => '~/Desktop/data_fields.txt') # writes the data file to '~/Desktop/data_fields.txt' and returns '~/Desktop/data_fields.txt'
    def dump_data_fields(template, options = {})
      cmd = @call.utf8_support? ? :dump_data_fields_utf8 : :dump_data_fields
      @call.pdftk(options.merge(:input => template, :operation => cmd))
    end

    # Fill out the fields of a form on the template pdf.
    # @param [String, File, Tempfile, StringIO] template is the file on which the form is based.
    # @param [Hash] data A Hash of key/value pairs of field names and field values.
    # @param [Hash] options is a hash containing statements for the wrapper.
    # @macro see_options
    # @note +:input+ in the options hash will be overwritten by +template+ and +:operation+ will be overwritten.
    # @return resource specified in +:output+, if +:output+ is not provided (or +nil+), return content of +stdout+ in a +StringIO+.
    # @example
    #   fill_form('~/Desktop/form.pdf', {'field_1' => 'tom', 'field_2' => 'marco'}) # returns +StringIO+ of the pdf with the form fields filled in
    #   fill_form('~/Desktop/form.pdf', {'field_1' => 'tom', 'field_2' => 'marco'}, :output => '~/Desktop/filled.pdf', :options => {:flatten => false}) # writes the pdf with the form fields filled in and flattened so that the fields can not be edited to '~/Desktop/filled.pdf'
    def fill_form(template, fdf, options ={})
      @call.pdftk(options.merge(:input => template, :operation => {:fill_form => fdf}))
    end

    # Dump the template file data.
    # @param [String, File, Tempfile, StringIO] template is the file on which the form is based.
    # @note +:input+ in the options hash will be overwritten by +template+ and +:operation+ will be overwritten.
    # @return resource specified in +:output+, if +:output+ is not provided (or +nil+), return content of +stdout+ in a +StringIO+.
    # @example
    #   dump_data('~/Desktop/a.pdf') # returns StringIO of the output
    #   dump_data('~/Desktop/a.pdf', :output => '~/Desktop/data.txt) # writes the data file to '~/Desktop/data.txt' and returns '~/Desktop/data.txt'
    def dump_data(template, options = {})
      cmd = @call.utf8_support? ? :dump_data_utf8 : :dump_data
      @call.pdftk(options.merge(:input => template, :operation => cmd))
    end

    # Modify the metadata info of the template pdf.
    # @param [String, File, Tempfile, StringIO] template is the file on which the form is based.
    # @param [String, File, Tempfile, StringIO] infos the data (in the same format as dump_data) that you want to change on the template file.
    # @param [Hash] options is a hash containing statements for the wrapper.
    # @macro see_options
    # @note +:input+ in the options hash will be overwritten by +template+ and +:operation+ will be overwritten.
    # @return resource specified in +:output+, if +:output+ is not provided (or +nil+), return content of +stdout+ in a +StringIO+.
    # @example
    #   update_info('~/Desktop/a.pdf', '~/Desktop/meta.txt') # returns StringIO of the new pdf
    #   update_info('~/Desktop/a.pdf', '~/Desktop/meta.txt', :output => '~/Desktop/b.pdf') # writes the new pdf to '~/Desktop/b.pdf' and returns '~/Desktop/b.pdf'
    def update_info(template, infos, options = {})
      cmd = @call.utf8_support? ? :update_info_utf8 : :update_info
      @call.pdftk(options.merge(:input => template, :operation => {cmd => infos}))
    end

    # Attach files to the template pdf.
    # @param [String, File, Tempfile, StringIO] template is the file on which the form is based.
    # @param [Array<String>] files to be attached to the pdf template.
    # @param [Hash] options is a hash containing statements for the wrapper.
    # @macro see_options
    # @note +:input+ in the options hash will be overwritten by +template+ and +:operation+ will be overwritten.
    # @return resource specified in +:output+, if +:output+ is not provided (or +nil+), return content of +stdout+ in a +StringIO+.
    # @example
    #   attach_files('~/Desktop/a.pdf', ['~/Desktop/b.txt']) # returns StringIO of the new pdf with the file attached
    #   attach_files('~/Desktop/a.pdf', ['~/Desktop/b.txt'], :output => '~/Desktop/b.pdf') # writes the new pdf to '~/Desktop/b.pdf' and returns '~/Desktop/b.pdf'
    def attach_files(template, files, options = {})
      @call.pdftk(options.merge(:input => template, :operation => {:attach_files => files}))
    end

    # Unpack attached file from the template pdf.
    # @param [String, File, Tempfile, StringIO] template is the file on which the form is based.
    # @param [String] directory location to unpack the files into.
    # @note +:input+ in the options hash will be overwritten by +template+ and +:operation+ will be overwritten.
    # @return resource specified in +:output+, if +:output+ is not provided (or +nil+), return +Dir.tmpdir+.
    # @example
    #   unpack_files('a.pdf', '~/Desktop') # will unpack the files to the desktop and return '~/Desktop'
    #   unpack_files('a.pdf') # will unpack the files to Dir.tmpdir and return Dir.tmpdir
    def unpack_files(template, directory = nil)
      @call.pdftk(:input => template, :operation => :unpack_files, :output => directory)
    end

    private

    # Takes and operation as a symbol and an array of ranges to construct the options hash.
    # @param [Symbol] operation
    # @param [Array] ranges an Array of range Hashes
    # @return [Hash] a hash of the inputs extracted from the ranges and the operation with the correct ranges passed in
    def call_range_operation(operation, ranges)
      inputs = {}
      ranges.each do |range|
        if range[:pdf]
          if !inputs.has_key?(range[:pdf]) || (inputs[range[:pdf]].nil? && !range[:pass].nil?)
            inputs[range[:pdf]] = range[:pass]
            range.delete(:pass)
          end
        end
      end
      {:input => inputs, :operation => {operation => ranges}}
    end

    # Takes a command, template file, overlay file and whether the command is a multi or single command to construct the options hash.
    # @param [Symbol] command
    # @param [String, File, Tempfile, StringIO] template is the file on which the form is based
    # @param [String, File, Tempfile, StringIO] overlay is the file which will be backgrounded or stamped
    # @param [Boolean] multi whether the command should be a multi command or not
    # @return [Hash] a hash of the input template and the operation with command and the overlay
    def call_multi_operation(command, template, overlay, multi)
      cmd = (multi == true ? "multi#{command}".to_sym : command.to_sym)
      {:input => template, :operation => {cmd => overlay}}
    end

  end
end
