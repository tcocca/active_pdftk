def path_to_pdf(filename)
  File.join File.dirname(__FILE__), '../', 'test_pdfs', "#{filename}"
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