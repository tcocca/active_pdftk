def valid_xfdf
  xfdf = Builder::XmlMarkup.new
  xfdf.instruct!
  xfdf.xfdf(:xmlns => "http://ns.adobe.com/xfdf/", :"xml:space" => "preserve") do
    xfdf.fields do
      xfdf.field(:name => :test) do
        xfdf.value "one"
      end
      xfdf.field(:name => :user) do
        xfdf.value "tom"
      end
    end
  end
  xfdf
end

def path_to_pdf(filename)
  File.join File.dirname(__FILE__), '../', 'test_pdfs', "#{filename}"
end
