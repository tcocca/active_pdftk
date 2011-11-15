RSpec::Matchers.define :have_the_content_of do |expected|
  match do |actual|
    sha256_hash_of(actual) == sha256_hash_of(expected)
  end

  diffable
end

#TODO it would be great to implement an inclusion matcher, just for fun.
#RSpec::Matchers.define :include_the_content_of do |expected|
#  match do |actual|
#    !(sha256_hash_of(expected) & sha256_hash_of(actual)).empty?
#  end
#end

def sha256_hash_of(entry)
  entry.rewind if entry.respond_to? :rewind
  case entry
    when File, Tempfile then Digest::SHA256.file(entry.path).hexdigest
    when Dir            then (entry.entries - ['.', '..']).collect { |filename| sha256_hash_of(Pathname.new(File.join(entry.path, filename))) }.compact.sort
    when StringIO       then sha256_hash_of(entry.read)
    when String         then
      if entry.size < 256 && (Pathname.new(entry).file? || Pathname.new(entry).directory?) # Would be deprecated in favor of Pathname object
        sha256_hash_of(Pathname.new(entry))
      else
        Digest::SHA256.hexdigest(entry)
      end
    when Pathname       then
      if entry.directory?
        sha256_hash_of(Dir.new(entry))
      elsif entry.file?
        sha256_hash_of(File.new(entry))
      end
  end
end