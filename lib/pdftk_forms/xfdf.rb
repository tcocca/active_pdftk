module PdftkForms
  class Xfdf
    
    def initialize(data = {})
      @data = data
    end
    
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
    
    def save_to(path)
      (File.open(path, 'w') << to_s).close
    end
    
  end
end
