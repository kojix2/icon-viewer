# Register a shard's PNG data without decoding every image during the build.
require "base64"

collection, shard = ARGV
source_dir = File.expand_path("../lib/#{shard}/src/data", __DIR__)
files = Dir.glob(File.join(source_dir, "*.tsv")).sort
abort "#{shard} is not installed in lib/#{shard}" if files.empty?

count = 0
names = Set(String).new
files.each do |file|
  File.each_line(file) do |line|
    name, encoded = line.split('\t', 2)
    abort "Invalid icon name in #{file}: #{name}" unless name.matches?(/\A[A-Z][A-Za-z0-9]*\z/)
    abort "Duplicate icon name: #{name}" unless names.add?(name)
    png = Base64.decode(encoded)
    abort "Invalid PNG for #{name}" unless png[0, 8] == Bytes[137, 80, 78, 71, 13, 10, 26, 10]
    width = (png[16].to_i << 24) | (png[17].to_i << 16) | (png[18].to_i << 8) | png[19].to_i
    height = (png[20].to_i << 24) | (png[21].to_i << 16) | (png[22].to_i << 8) | png[23].to_i
    abort "Unexpected dimensions for #{name}: #{width}x#{height}" unless width.in?(1..1024) && height.in?(1..1024)
    puts %(icons << ViewerIcon.new(#{collection.inspect}, #{name.inspect}, #{encoded.inspect}, #{width}, #{height}))
    count += 1
  end
end
abort "No icons found in #{source_dir}" if count == 0
