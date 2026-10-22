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

  def initialize(@collection : String, @name : String, @encoded_png : String, @width : Int32, @height : Int32)
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
  def self.all : Array(ViewerIcon)
    icons = [] of ViewerIcon
    {{ run("../scripts/png_catalog", "Radix", "icon-radix") }}
    {{ run("../scripts/png_catalog", "Fluent", "icon-fluent") }}
    {{ run("../scripts/png_catalog", "Octicons", "icon-octicons") }}
    {{ run("../scripts/png_catalog", "Eva", "icon-eva") }}
    {{ run("../scripts/png_catalog", "Ionic", "icon-ionic") }}
    icons
  end
end
