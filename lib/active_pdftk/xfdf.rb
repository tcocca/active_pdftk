module ActivePdftk

  # Map keys and values to Adobe's XFDF format.
  #
  class Xfdf

    # Creates a new instance given the field names and values provided as a hash
    #
    # @param[Hash] A hash of fields where the key is the field name and the value is the value for the field.  The value can also be a nested hash of fields.
    #
    def initialize(data = {})
      @data = data
    end

    # Generates a string of XFDF format using the +@data+ hash to construct the field and value pairs
    #
    # Uses Builder to construct the XML
    #
    # @return [String]
    #
    def to_s
      xfdf = Builder::XmlMarkup.new
      xfdf.instruct!
      xfdf.xfdf(:xmlns => "http://ns.adobe.com/xfdf/", :"xml:space" => "preserve") do
        xfdf.fields do
          @data.each do |key, value|
            if Hash === value
              value.each do |sub_key, sub_value|
                xfdf.field(:name => "#{key}_#{sub_key}") do
                  xfdf.value sub_value
                end
              end
            else
              xfdf.field(:name => key) do
                xfdf.value value
              end
            end
          end
        end
      end
      xfdf.target!
    end

    # Writes the output from #to_s to a file at the specified path
    #
    # @param [String] path to save the generated file to
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

  end
end
