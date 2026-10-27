require "uing/crimage"
require "base64"
require "icon-radix/common"
require "icon-fluent/common"
require "icon-octicons/common"
require "icon-eva/common"
require "icon-ionic/common"

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
    if @collection == "Octicons" && (match = name.match(/(12|16|24|48|96)\z/))
      match[1]
    elsif @collection == "Ionic" && name.starts_with?("Logo") && (match = name.match(/(24|32)\z/))
      "#{match[1]} Logos"
    elsif @collection == "Fluent" && (match = name.match(/(10|12|16|20|24|28|32|48)(Regular|Filled|Light|Color)\z/))
      "#{match[1]} #{match[2]}"
    elsif @collection == "Eva" && (match = name.match(/(24)(Filled|Outline)\z/))
      "#{match[1]} #{match[2]}"
    elsif @collection == "Ionic" && (match = name.match(/(24|32)(Filled|Outline|Sharp)\z/))
      "#{match[1]} #{match[2]}"
    else
      ""
    end
  end

  def native : UIng::Image
    if image = @native
      return image
    end
    @native = decode_native
  end

  # Returns an independently owned image for surfaces with their own cache.
  def decode_native : UIng::Image
    source = CrImage.read(IO::Memory.new(Base64.decode(@encoded_png)))
    bounds = source.bounds
    unless bounds.width == @width && bounds.height == @height
      raise "#{@collection}::#{@name} decoded to #{bounds.width}x#{bounds.height}, expected #{@width}x#{@height}"
    end
    UIng::Image.from_crimage(source)
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
  def self.all : Array(ViewerIcon)
    icons = [] of ViewerIcon
    Icon::Radix.each_icon_data do |name, encoded|
      icons << ViewerIcon.new("Radix", {{ name }}, {{ encoded }})
    end
    Icon::Fluent.each_icon_data do |name, encoded|
      icons << ViewerIcon.new("Fluent", {{ name }}, {{ encoded }})
    end
    Icon::Octicons.each_icon_data do |name, encoded|
      icons << ViewerIcon.new("Octicons", {{ name }}, {{ encoded }})
    end
    Icon::Eva.each_icon_data do |name, encoded|
      icons << ViewerIcon.new("Eva", {{ name }}, {{ encoded }})
    end
    Icon::Ionic.each_icon_data do |name, encoded|
      icons << ViewerIcon.new("Ionic", {{ name }}, {{ encoded }})
    end
    icons
  end
end
