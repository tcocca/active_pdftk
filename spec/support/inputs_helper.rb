def path_to_pdf(filename)
  File.expand_path(File.join(File.dirname(__FILE__), '../', 'fixtures', "#{filename}"))
end

def fixtures_path(entry, expand = false)
  entry_path = Pathname.new(File.expand_path(File.join(File.dirname(__FILE__), '../', 'fixtures', "#{entry}")))
  if expand && entry_path.directory?
    entry_path.children
  else
    entry_path
  end
end

# Because with Ruby 1.8 Hashes are unordered, and options in cli are unordered too,
# two command lines could seems different but have the same behaviour.
# With Ruby 1.9 command line should always be identical.
# In order to specs this we could (and did) compare a sorted array of characters composing the command line
# it is not bulletproof but command line anagrams are very unlikely.

# Here we reconstruct the options hash (only inputs for now) in order to test the stuff.
# Anybody with a better solution should make a proposal.
def reconstruct_inputs(chain)
  tested_inputs = Hash.new
  chain.scan(/([A-Z])=(\S*)/).each do |item|
    if tested_inputs[item.first]
      tested_inputs[item.first] = [tested_inputs[item.first].first, item.last]
    else
      tested_inputs[item.first] = [item.last, nil]
    end
  end
  Hash[tested_inputs.values]
end

def map_inputs(input_pdfs)
  inputs = input_pdfs.split(' ')
  input_map = {}
  inputs.each do |input|
    parts = input.split('=')
    input_map[parts[1]] = parts[0]
  end
  input_map
end

def remove_output(output)
  if output.is_a?(String)
    File.unlink(output)
  elsif output.is_a?(File)
    File.unlink(output.path)
  end
end

def open_or_rewind(target)
  if target.is_a? String
    File.new(target).read
  else
    target.rewind if target.respond_to? :rewind
    target.read
  end
end

def cleanup_file_content!(text)

  unless @filter
    @filter = {
        :date => /\(D\:.*\)/,                   # Remove dates ex: /CreationDate (D:20111106104455-05'00')
        :ids => /\/ID \[<\w*><\w*>\]/,          # Remove ID values ex: /ID [<4ba02a4cf55b1fc842299e6f01eb838e><33bec7dc37839cadf7ab76f3be4d4306>]
        :stream => /stream .* 9|10 0 obj /m,    # Remove some binary stream
        :content => /\/Contents \[.*\]/,
        :xref => /^\d{10} \d{5} n|f $/          # Remove Cross-references dictionnary
    }
    @filter.each {|k,reg| @filter[k] = Regexp.new(reg.source.encode('ASCII-8BIT'), reg.options) if reg.source.respond_to? :encode }
  end


  text.force_encoding('ASCII-8BIT') if text.respond_to? :force_encoding   # PDF embed some binary data breaking gsub with ruby 1.9.2
  @filter.each {|k,reg| text.gsub!(reg, '')}
  text
end

def cleanup_file_content(text)
  cleanup_file_content!(text.dup)
end