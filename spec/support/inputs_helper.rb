def path_to_pdf(filename)
  File.expand_path(File.join(File.dirname(__FILE__), '../', 'fixtures', "#{filename}"))
end

def fixtures_path(entry, expand = false)
  entry_path = Pathname.new(File.expand_path(File.join(File.dirname(__FILE__), '../', 'fixtures', "#{entry}")))
  if expand && entry_path.directory?
    (entry_path.entries - [Pathname.new('.'), Pathname.new('..')]).collect { |obj| entry_path + obj}
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