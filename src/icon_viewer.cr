require "./icon_catalog"
require "./icon_search"
require "./icon_variants"

# Table image values borrow ViewerIcon images. Release the final page only
# after the native table has actually finished destruction.
private class ViewerTable < UIng::Table
  def initialize(model : UIng::Table::Model, @icons : Array(ViewerIcon))
    super(model)
  end

  protected def after_destroy : Nil
    super
    @icons.each(&.free)
  end
end

class IconViewer
  PAGE_SIZE = 256
  VERSION = "0.1.0"
  PROJECT_URL = "https://github.com/kojix2/icon-viewer"

  @collections : Array(String)
  @variant_options : Array(String)

  def initialize
    @icons = IconCatalog.all
    @collections = @icons.map(&.collection).uniq!
    @icons.sort_by! { |icon| {icon.collection, icon.name} }
    @variant_options = [IconVariants::ALL]
    @updating_variants = false
    @matches = [] of ViewerIcon
    @visible = [] of ViewerIcon
    @page_index = 0
    @current_index = -1

    @window = UIng::Window.new("Icon Viewer", 700, 480, margined: true)
    @collection = UIng::Combobox.new(@collections)
    @collection.selected = 0
    @collection.tooltip = "Choose an icon collection"
    @variant = UIng::Combobox.new(@variant_options)
    @variant.selected = 0
    @variant.tooltip = "Choose a size and style"
    @search = UIng::Entry.new(:search)
    @search.tooltip = "Search icons by name"
    @preview = UIng::ImageView.new
    @preview.content_mode = UIng::ImageView::ContentMode::Fit
    @selected_name = UIng::Label.new("Select an icon")
    @constant = UIng::Entry.new(read_only: true)
    @constant.tooltip = "Select the field and press Ctrl+A / Ctrl+C (Command on macOS) to copy."
    @dimensions = UIng::Label.new("")
    @status = UIng::Label.new("")
    @page_label = UIng::Label.new("")
    @previous_page = UIng::Button.new("Previous page")
    @next_page = UIng::Button.new("Next page")
    @list_panel = UIng::Box.new(:vertical, padded: true)

    visible = @visible
    handler = UIng::Table::Model::Handler.new do
      num_columns { 2 }
      column_type do |col|
        col == 0 ? UIng::Table::Value::Type::Image : UIng::Table::Value::Type::String
      end
      num_rows { visible.size }
      cell_value do |row, col|
        icon = visible[row]
        col == 0 ? UIng::Table::Value.new(icon.cached_native) : UIng::Table::Value.new(icon.name)
      end
      set_cell_value { |_row, _col, _value| }
    end
    @model = UIng::Table::Model.new(handler)
    @table = ViewerTable.new(@model, @icons)
    @table.append_image_column("Icon", 0)
    @table.append_text_column("Name", 1, editable: :never)
    @table.selection_mode = UIng::Table::Selection::Mode::ZeroOrOne
    @table.column_set_width(0, 60)
    @table.column_set_width(1, 240)

    make_layout
    make_toolbar
    bind_events
    update_variants
  end

  def run : Nil
    @window.show
    UIng.main
  end

  private def make_layout : Nil
    root = UIng::Box.new(:vertical, padded: true)
    search_row = UIng::Box.new(:horizontal, padded: true)
    search_row.append(@collection, false)
    search_row.append(@variant, false)
    search_row.append(@search, true)

    page_row = UIng::Box.new(:horizontal, padded: true)
    page_row.append(@previous_page, false)
    page_row.append(@page_label, true)
    page_row.append(@next_page, false)

    @list_panel.append(@table, true)
    @list_panel.append(page_row, false)

    detail_panel = UIng::Box.new(:vertical, padded: true)
    detail_panel.append(@preview, true)
    detail_panel.append(@selected_name, false)
    detail_panel.append(UIng::Label.new("Crystal constant"), false)
    detail_panel.append(@constant, false)
    detail_panel.append(@dimensions, false)

    content = UIng::Box.new(:horizontal, padded: true)
    content.append(@list_panel, true)
    content.append(detail_panel, true)

    root.append(search_row, false)
    root.append(content, true)
    root.append(@status, false)
    @window.child = root
  end

  private def make_toolbar : Nil
    toolbar_images = %w[ChevronLeft ChevronRight Shuffle Cross2 InfoCircled].map do |name|
      icon = @icons.find { |candidate| candidate.collection == "Radix" && candidate.name == name } || raise "Missing toolbar icon: #{name}"
      icon.native
    end
    toolbar = UIng::Toolbar.new
    toolbar.display_mode = UIng::Toolbar::DisplayMode::IconAndTextVertical

    previous = toolbar.append_button("Previous", toolbar_images[0])
    previous.tooltip = "Previous matching icon"
    previous.on_clicked { move(-1) }

    following = toolbar.append_button("Next", toolbar_images[1])
    following.tooltip = "Next matching icon"
    following.on_clicked { move(1) }

    random = toolbar.append_button("Random", toolbar_images[2])
    random.tooltip = "Pick a random matching icon"
    random.on_clicked { jump_to_match(Random.rand(@matches.size)) unless @matches.empty? }

    toolbar.append_separator

    clear = toolbar.append_button("Clear", toolbar_images[3])
    clear.tooltip = "Clear the search filter"
    clear.on_clicked do
      @search.text = ""
      filter("")
    end

    toolbar.append_separator

    info = toolbar.append_button("Info", toolbar_images[4])
    info.tooltip = "About Icon Viewer"
    info.on_clicked do
      @window.msg_box("About Icon Viewer", "Icon Viewer\nVersion #{VERSION}\n#{PROJECT_URL}")
    end

    # UIng copies item images and frees the attached toolbar with its window.
    @window.toolbar = toolbar
  end

  private def bind_events : Nil
    @search.on_changed { |query| filter(query) }
    @collection.on_selected { update_variants }
    @variant.on_selected { filter(@search.text || "") unless @updating_variants }
    @previous_page.on_clicked { show_page(@page_index - 1) }
    @next_page.on_clicked { show_page(@page_index + 1) }

    @table.on_selection_changed do |selection|
      if row = selection.rows.first?
        show_icon(row) if row >= 0 && row < @visible.size
      end
    end

    @window.on_closing do
      # Table destruction may be deferred until this native callback returns.
      # ViewerTable releases the borrowed images on actual destruction.
      @list_panel.delete(0)
      @table.destroy
      @model.free
      UIng.quit
      true
    end
  end

  private def show_icon(index : Int32) : Nil
    return unless icon = @visible[index]?
    @current_index = index
    @preview.image = icon.native
    @selected_name.text = icon.name
    @constant.text = "Icon::#{icon.collection}::#{icon.name}"
    @dimensions.text = "#{icon.width} × #{icon.height} px"
    @status.text = "#{@page_index * PAGE_SIZE + index + 1} / #{@matches.size} matches   •   #{collection_total} #{@collections[@collection.selected || 0]} icons"
  end

  private def select_icon(index : Int32) : Nil
    return unless @visible[index]?
    show_icon(index)
    @table.selection = UIng::Table::Selection.new([index])
  end

  private def move(offset : Int32) : Nil
    return if @matches.empty?
    index = (@page_index * PAGE_SIZE + @current_index + offset).clamp(0, @matches.size - 1)
    jump_to_match(index)
  end

  private def filter(query : String) : Nil
    tokens = IconSearch.tokens(query)
    selected_collection = @collections[@collection.selected || 0]
    selected_variant = @variant_options[@variant.selected || 0]
    @matches.clear
    @icons.each do |icon|
      if icon.collection == selected_collection && (selected_variant == IconVariants::ALL || icon.variant == selected_variant) && IconSearch.matches?(IconSearch.normalize(icon.name), tokens)
        @matches << icon
      end
    end
    show_page(0)
  end

  private def jump_to_match(index : Int32) : Nil
    page = index // PAGE_SIZE
    if page == @page_index
      select_icon(index % PAGE_SIZE)
    else
      show_page(page, index % PAGE_SIZE)
    end
  end

  private def show_page(page : Int32, selected_row : Int32 = 0) : Nil
    page_count = (@matches.size + PAGE_SIZE - 1) // PAGE_SIZE
    next_page = page.clamp(0, {page_count - 1, 0}.max)
    start = next_page * PAGE_SIZE
    new_visible = @matches[start, PAGE_SIZE]
    old_visible = @visible.dup

    # Decode before changing the GTK table. Its cell_value callback only
    # returns images that are already owned by the catalog.
    new_visible.each(&.native)
    @page_index = next_page

    # Keep the Table model and the Crystal backing array in sync, row by row.
    # Sending row_deleted/row_inserted is supported on all UIng platforms.
    @table.selection = UIng::Table::Selection.new([] of Int32)
    until @visible.empty?
      @visible.pop
      @model.row_deleted(@visible.size)
    end

    selected_collection = @collections[@collection.selected || 0]
    new_visible.each do |icon|
      @visible << icon
      @model.row_inserted(@visible.size - 1)
    end

    @page_label.text = page_count == 0 ? "Page 0 / 0" : "Page #{@page_index + 1} / #{page_count}"
    @page_index > 0 ? @previous_page.enable : @previous_page.disable
    @page_index + 1 < page_count ? @next_page.enable : @next_page.disable

    if @visible.empty?
      @current_index = -1
      @preview.image = nil
      @selected_name.text = "No matches"
      @constant.text = ""
      @dimensions.text = ""
      @status.text = "0 matches   •   #{collection_total} #{selected_collection} icons"
    else
      select_icon(selected_row)
    end

    # Row notifications are complete, and ImageView keeps its own copy.
    # Images outside the current page are no longer borrowed by the table.
    old_visible.each { |icon| icon.free unless @visible.includes?(icon) }
  end

  private def update_variants : Nil
    selected_collection = @collections[@collection.selected || 0]
    @updating_variants = true
    begin
      @variant_options = IconVariants.options(@icons.select { |icon| icon.collection == selected_collection }.map(&.variant))
      @variant.clear
      @variant_options.each { |option| @variant.append(option) }
      @variant.selected = 0
      @variant_options.size > 1 ? @variant.enable : @variant.disable
    ensure
      @updating_variants = false
    end
    filter(@search.text || "")
  end

  private def collection_total : Int32
    selected_collection = @collections[@collection.selected || 0]
    @icons.count { |icon| icon.collection == selected_collection }
  end
end

UIng.init
begin
  IconViewer.new.run
ensure
  UIng.uninit
end
