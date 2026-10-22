require "uing/crimage"
require "base64"

class ViewerIcon
  getter name : String
  getter collection : String
  getter variant : String
  getter width : Int32
  getter height : Int32
  @encoded_png : String
  @native : UIng::Image?

  def initialize(@collection : String, @name : String, @encoded_png : String)
    header = Base64.decode(@encoded_png[0, 32])
    unless header.size >= 24 && header[0, 8] == Bytes[137, 80, 78, 71, 13, 10, 26, 10]
      raise "Invalid PNG for #{@collection}::#{@name}"
    end
    @width = (header[16].to_i << 24) | (header[17].to_i << 16) | (header[18].to_i << 8) | header[19].to_i
    @height = (header[20].to_i << 24) | (header[21].to_i << 16) | (header[22].to_i << 8) | header[23].to_i
    unless @width.in?(1..1024) && @height.in?(1..1024)
      raise "Invalid PNG dimensions for #{@collection}::#{@name}: #{@width}x#{@height}"
    end
    @variant = variant_for(@name)
  end

  private def variant_for(name : String) : String
    if @collection == "Octicons" && (match = name.match(/(\d+)\z/))
      match[1]
    elsif @collection == "Ionic" && name.starts_with?("Logo") && (match = name.match(/(\d+)\z/))
      "#{match[1]} Logos"
    elsif match = name.match(/(\d+)(Regular|Filled|Light|Color|Outline|Sharp)\z/)
      "#{match[1]} #{match[2]}"
    else
      ""
    end
  end

  def native : UIng::Image
    if image = @native
      return image
    end
    source = CrImage.read(IO::Memory.new(Base64.decode(@encoded_png)))
    bounds = source.bounds
    unless bounds.width == @width && bounds.height == @height
      raise "#{@collection}::#{@name} decoded to #{bounds.width}x#{bounds.height}, expected #{@width}x#{@height}"
    end
    @native = UIng::Image.from_crimage(source)
    @native.not_nil!
  end

  def cached_native : UIng::Image
    @native || raise "#{@collection}::#{@name} was not loaded before table display"
  end

  def free : Nil
    @native.try &.free
    @native = nil
  end
end

module IconCatalog
  macro add_icons(collection, shard, groups)
    {% for group in groups %}
      {% for line in read_file("#{__DIR__}/../lib/#{shard.id}/src/data/#{group.id}.tsv").lines %}
        {% fields = line.strip.split("\t") %}
        icons << ViewerIcon.new({{ collection }}, {{ fields[0] }}, {{ fields[1] }})
      {% end %}
    {% end %}
  end

  def self.all : Array(ViewerIcon)
    icons = [] of ViewerIcon
    add_icons("Radix", "icon-radix", ["icons"])
    add_icons("Fluent", "icon-fluent", [
      "10_filled", "10_regular", "12_filled", "12_regular",
      "16_color", "16_filled", "16_regular",
      "20_color", "20_filled", "20_regular",
      "24_color", "24_filled", "24_light", "24_regular",
      "28_color", "28_filled", "28_light", "28_regular",
      "32_color", "32_filled", "32_light", "32_regular",
      "48_color", "48_filled", "48_light", "48_regular",
    ])
    add_icons("Octicons", "icon-octicons", ["12", "16", "24", "48", "96"])
    add_icons("Eva", "icon-eva", ["24_filled", "24_outline"])
    add_icons("Ionic", "icon-ionic", [
      "24_filled", "24_logos", "24_outline", "24_sharp",
      "32_filled", "32_logos", "32_outline", "32_sharp",
    ])
    icons
  end
end
