require "./icon_catalog"
require "./icon_grid_layout"

# One native scrolling surface, with a bounded cache instead of one native
# control (or a decoded image) for every catalog entry.
class IconGrid < UIng::Area
  CACHE_SIZE = 256

  @items = [] of ViewerIcon
  @layout = IconGridLayout.new(0)
  @selected = -1
  @images = {} of Int32 => UIng::Image
  @on_selected : Proc(Int32, Nil)?
  @font : UIng::FontDescriptor

  def initialize
    super(@layout.width, @layout.height)
    @font = UIng::FontDescriptor.new(size: 10)
    self.tooltip = "Click an icon to preview it. Use arrow keys, Home, or End to browse."
    on_draw { |params| draw_icons(params) }
    on_mouse_event do |event|
      if event.down == 1 && (index = @layout.index_at(event.x, event.y))
        @on_selected.try &.call(index)
      end
    end
    on_key_event do |event|
      if event.up? || event.modifiers != UIng::Modifiers::None
        false
      else
        direction = case event.ext_key
                    when UIng::ExtKey::Left  then :left
                    when UIng::ExtKey::Right then :right
                    when UIng::ExtKey::Up    then :up
                    when UIng::ExtKey::Down  then :down
                    when UIng::ExtKey::Home  then :home
                    when UIng::ExtKey::End   then :end
                    end
        if direction && (index = @layout.move(@selected, direction))
          @on_selected.try &.call(index)
          true
        else
          false
        end
      end
    end
  end

  def on_selected(&block : Int32 -> Nil) : Nil
    @on_selected = block
  end

  def items=(items : Array(ViewerIcon)) : Nil
    release_images
    @items = items.dup
    @selected = -1
    @layout = IconGridLayout.new(@items.size, @layout.columns)
    set_size(@layout.width, @layout.height)
    scroll_to(0, 0, 1, 1)
    queue_redraw_all
  end

  def columns=(columns : Int32) : Nil
    @layout = IconGridLayout.new(@items.size, columns)
    set_size(@layout.width, @layout.height)
    select_icon(@selected)
    queue_redraw_all
  end

  def select_icon(index : Int32, reveal : Bool = true) : Nil
    return unless @items[index]?
    @selected = index
    if reveal
      x, y = @layout.position(index)
      scroll_to(x, y, IconGridLayout::CELL_WIDTH, IconGridLayout::CELL_HEIGHT)
    end
    queue_redraw_all
  end

  protected def after_destroy : Nil
    super
    release_images
    @on_selected = nil
  end

  private def release_images : Nil
    @images.each_value(&.free)
    @images.clear
  end

  private def image_for(index : Int32) : UIng::Image
    # Moving hits to the end makes Hash insertion order an LRU queue. These
    # images are independent of the catalog images borrowed by the list table.
    image = @images.delete(index) || @items[index].decode_native
    @images[index] = image
    while @images.size > CACHE_SIZE
      oldest = @images.first_key
      @images.delete(oldest).try &.free
    end
    image
  end

  private def draw_icons(params : UIng::Area::Draw::Params) : Nil
    context = params.context
    background = UIng::Area::Draw::Brush.new(:solid, 1, 1, 1)
    context.fill_path(background) do |path|
      path.add_rectangle(params.clip_x, params.clip_y, params.clip_width, params.clip_height)
    end

    if @items.empty?
      draw_label(context, "No matches", IconGridLayout::PADDING, IconGridLayout::PADDING, @layout.width - 16)
      return
    end

    selection = UIng::Area::Draw::Brush.new(:solid, 0.84, 0.91, 1)
    border = UIng::Area::Draw::Brush.new(:solid, 0.19, 0.44, 0.80)
    @layout.visible_indices(params.clip_y, params.clip_height).each do |index|
      x, y = @layout.position(index)
      next if x + IconGridLayout::CELL_WIDTH <= params.clip_x || x >= params.clip_x + params.clip_width

      if index == @selected
        context.fill_path(selection) do |path|
          path.add_rectangle(x + 2, y + 2, IconGridLayout::CELL_WIDTH - 4, IconGridLayout::CELL_HEIGHT - 4)
        end
        context.stroke_path(border) do |path|
          path.add_rectangle(x + 2, y + 2, IconGridLayout::CELL_WIDTH - 4, IconGridLayout::CELL_HEIGHT - 4)
        end
      end

      icon = @items[index]
      scale = {32.0 / icon.width, 32.0 / icon.height}.min
      width, height = icon.width * scale, icon.height * scale
      context.draw_image(image_for(index), x + (IconGridLayout::CELL_WIDTH - width) / 2, y + 12 + (32 - height) / 2, width, height)
      name = icon.name.size > 14 ? "#{icon.name[0, 13]}…" : icon.name
      draw_label(context, name, x + 4, y + 54, IconGridLayout::CELL_WIDTH - 8)
    end
  end

  private def draw_label(context : UIng::Area::Draw::Context, text : String, x : Int32, y : Int32, width : Int32) : Nil
    UIng::Area::AttributedString.open(text) do |string|
      string.set_attribute(UIng::Area::Attribute.new_color(0.15, 0.15, 0.15, 1), 0, string.len)
      UIng::Area::Draw::TextLayout.open(string, @font, width, :center) do |layout|
        context.draw_text_layout(layout, x, y)
      end
    end
  end
end
