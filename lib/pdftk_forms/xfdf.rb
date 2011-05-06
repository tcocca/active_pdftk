module PdftkForms
  class Xfdf
    
    def initialize(data = {})
      @data = data
    end
    
    def to_xfdf
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
      xfdf
    end
    
    def save_to(path)
      xml = to_xfdf.target!
      (File.open(path, 'w') << xml).close
    end
    
  end
end
