module ActivePdftk
  
  # Map keys and values to Adobe's FDF format.
  #
  # Straight port of Perl's PDF::FDF::Simple by Steffen Schwigon.
  #
  # FDF can be returned as a string with #to_s or written to a file with #save_to('file_path')
  #
  # Parsing FDF files is not supported (yet).
  #
  class Fdf

    # @return [Hash] the options for FDF ('file', 'ufile' and 'id') all of which are optional for the header
    attr_reader :options

    # Creates a new instance given the field names and values provided as a hash.
    #
    # @param[Hash] A hash of fields where the key is the field name and the value is the value for the field.  The value can also be a nested hash of fields.
    # @param[Hash] options optional header options for the FDF
    # @option options [String] :file, optional, The source file or target file: the PDF document file that this FDF file was exported from or is intended to be imported into. This option corresponds to the /F attribute in FDF content.
    # @option options [String] :ufile, optional, The corresponding PDF filename of the form. This method corresponds to the /UF attribute in FDF content.
    # @option options [String] :id, optional, An array of two strings constituting a file identifier. This method corresponds to the ID attribute in FDF content.
    #
    def initialize(data = {}, options = {})
      @data = data
      @options = {
        :file => nil,
        :ufile => nil,
        :id => nil
      }.merge(options)
    end

    # Generates a string of FDF using the +@data+ hash to construct the field and value pairs.
    #
    # @return [String]
    #
    def to_s
      fdf = header
      @data.each do |key, value|
        if Hash === value
          value.each do |sub_key, sub_value|
            fdf << field("#{key}_#{sub_key}", sub_value)
          end
        else
          fdf << field(key, value)
        end
      end
      fdf << footer
      return fdf
    end
    
    # Writes the output from #to_s to a file at the specified path.
    #
    # @param [String] path to save the generated file to.
    #
    # @return [String]
    #
    # @example
    #   save_to('/path/to/file') #=> "/path/to/file"
    #   save_to(File.join('path', 'to', 'file')) #=> "/path/to/file"
    #
    def save_to(path)
      (File.open(path, 'w') << to_s).close
      path
    end

    protected

    # Constructs the header of the FDF.
    # Adds the optional component of the header if they exist in the +options+ hash.
    #
    # @return [String]
    #
    def header
      header = "%FDF-1.2\n\n1 0 obj\n<<\n/FDF << /Fields 2 0 R"
      # /F
      header << "/F (#{options[:file]})" if options[:file]
      # /UF
      header << "/UF (#{options[:ufile]})" if options[:ufile]
      # /ID
      header << "/ID[" << options[:id].join << "]" if options[:id]
      header << ">>\n>>\nendobj\n2 0 obj\n["
      return header
    end

    # Constructs a string of FDF for a specific field.
    #
    # @param[String] name of the field.
    # @param[String] value that you want to set on the field.
    #
    # @return [String]
    #
    def field(key, value)
      "<</T(#{key})/V" +
        (Array === value ? "[#{value.map{ |v|"(#{quote(v)})" }.join}]" : "(#{quote(value)})") +
        ">>\n"
    end

    # Removes escaped slashes and parenthesis and newlines from a string and returns the string.
    #
    # @return [String]
    #
    def quote(value)
      value.to_s.strip.
        gsub( /\\/, '\\' ).
        gsub( /\(/, '\(' ).
        gsub( /\)/, '\)' ).
        gsub( /\n/, '\r' )
    end

    # Used to add the footer to the markup of the FDF.
    #
    # @return [String]
    #
    def footer
      <<-EOFOOTER
]
endobj
trailer
<<
/Root 1 0 R

>>
%%EOF
EOFOOTER
    end

  end
end
