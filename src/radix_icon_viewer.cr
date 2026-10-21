require "uing/crimage"
require "icon/radix"

# Native images are shared by the table and toolbar. ImageView copies its image.
class RadixIcon
  getter name : String
  getter native : UIng::Image

  def initialize(@name : String, source : CrImage::Image)
    @native = UIng::Image.from_crimage(source)
  end

  def free : Nil
    @native.free
  end
end

class RadixIconViewer
  @toolbar_images : Array(UIng::Image)

  def initialize
    # The catalog is generated from icon-radix's actual constants at compile time.
    # No duplicate hand-maintained name list is needed.
    @icons = [] of RadixIcon
    {% for constant in Icon::Radix.constants %}
      @icons << RadixIcon.new({{ constant.stringify }}, Icon::Radix::{{ constant.id }})
    {% end %}
    @icons.sort_by!(&.name)
    @visible = @icons.dup
    @current_index = -1

    @window = UIng::Window.new("Radix Icon Viewer", 580, 400, margined: true)
    @search = UIng::Entry.new(:search)
    @preview = UIng::ImageView.new
    @preview.content_mode = UIng::ImageView::ContentMode::Fit
    @selected_name = UIng::Label.new("Select an icon")
    @constant = UIng::Entry.new(read_only: true)
    @status = UIng::Label.new("#{@icons.size} Radix icons")
    @list_panel = UIng::Box.new(:vertical, padded: true)
    @toolbar = UIng::Toolbar.new
    @toolbar_images = %w[ChevronLeft ChevronRight Shuffle Cross2 MixerHorizontal QuestionMarkCircled].map do |name|
      icon = @icons.find { |candidate| candidate.name == name } || raise "Missing toolbar icon: #{name}"
      icon.native
    end

    visible = @visible
    handler = UIng::Table::Model::Handler.new do
      num_columns { 2 }
      column_type do |col|
        col == 0 ? UIng::Table::Value::Type::Image : UIng::Table::Value::Type::String
      end
      num_rows { visible.size }
      cell_value do |row, col|
        icon = visible[row]
        col == 0 ? UIng::Table::Value.new(icon.native) : UIng::Table::Value.new(icon.name)
      end
      set_cell_value { |_row, _col, _value| }
    end
    @model = UIng::Table::Model.new(handler)
    @table = UIng::Table.new(@model) do
      append_image_column("Icon", 0)
      append_text_column("Name", 1, editable: :never)
    end
    @table.selection_mode = UIng::Table::Selection::Mode::ZeroOrOne
    @table.column_set_width(0, 60)
    @table.column_set_width(1, 240)

    make_layout
    make_toolbar
    bind_events
    select_icon(0)
  end

  def run : Nil
    @window.show
    UIng.main
  end

  private def make_layout : Nil
    root = UIng::Box.new(:vertical, padded: true)
    search_row = UIng::Box.new(:horizontal, padded: true)
    search_row.append(UIng::Label.new("Filter:"), false)
    search_row.append(@search, true)

    @list_panel.append(UIng::Label.new("ALL ICONS"), false)
    @list_panel.append(@table, true)

    detail_panel = UIng::Box.new(:vertical, padded: true)
    detail_panel.append(UIng::Label.new("PREVIEW"), false)
    detail_panel.append(@preview, true)
    detail_panel.append(@selected_name, false)
    detail_panel.append(UIng::Label.new("Crystal constant (select to copy):"), false)
    detail_panel.append(@constant, false)
    detail_panel.append(UIng::Label.new("Original icon size: 15 × 15 px"), false)

    content = UIng::Box.new(:horizontal, padded: true)
    content.append(@list_panel, true)
    content.append(detail_panel, true)

    root.append(search_row, false)
    root.append(content, true)
    root.append(@status, false)
    @window.child = root
  end

  private def make_toolbar : Nil
    @toolbar.display_mode = UIng::Toolbar::DisplayMode::IconAndTextVertical

    previous = @toolbar.append_button("Previous", @toolbar_images[0])
    previous.tooltip = "Previous matching icon"
    previous.on_clicked { move(-1) }

    following = @toolbar.append_button("Next", @toolbar_images[1])
    following.tooltip = "Next matching icon"
    following.on_clicked { move(1) }

    random = @toolbar.append_button("Random", @toolbar_images[2])
    random.tooltip = "Pick a random matching icon"
    random.on_clicked { select_icon(Random.rand(@visible.size)) unless @visible.empty? }

    @toolbar.append_separator

    clear = @toolbar.append_button("Clear", @toolbar_images[3])
    clear.tooltip = "Clear the search filter"
    clear.on_clicked { @search.text = "" }

    compact = @toolbar.append_toggle_button("Compact", @toolbar_images[4])
    compact.tooltip = "Toggle toolbar labels"
    compact.on_clicked do |item|
      @toolbar.display_mode = item.checked? ? UIng::Toolbar::DisplayMode::IconOnly : UIng::Toolbar::DisplayMode::IconAndTextVertical
    end

    @toolbar.append_separator

    help = @toolbar.append_button("Help", @toolbar_images[5])
    help.tooltip = "About this application"
    help.on_clicked do
      @window.msg_box("Radix Icon Viewer", "Browse #{@icons.size} Radix icons.\nType in the search field to filter.\nUse the toolbar or click a row to select an icon.\nThe constant name can be copied from the field below the preview.")
    end

    @window.toolbar = @toolbar
  end

  private def bind_events : Nil
    @search.on_changed { |query| filter(query) }

    @table.on_selection_changed do |selection|
      if row = selection.rows.first?
        show_icon(row) if row >= 0 && row < @visible.size
      end
    end

    @window.on_closing do
      # Toolbar borrows all image references; detach and free it first.
      @window.toolbar = nil
      @toolbar.free

      # A Table must be destroyed before its Model and model images are freed.
      @list_panel.delete(1)
      @table.destroy
      @model.free
      @icons.each &.free
      UIng.quit
      true
    end
  end

  private def show_icon(index : Int32) : Nil
    return unless icon = @visible[index]?
    @current_index = index
    @preview.image = icon.native
    @selected_name.text = icon.name
    @constant.text = "Icon::Radix::#{icon.name}"
    @status.text = "#{index + 1} / #{@visible.size} matches   •   #{@icons.size} total"
  end

  private def select_icon(index : Int32) : Nil
    return unless @visible[index]?
    show_icon(index)
    @table.selection = UIng::Table::Selection.new([index])
  end

  private def move(offset : Int32) : Nil
    return if @visible.empty?
    index = (@current_index + offset).clamp(0, @visible.size - 1)
    select_icon(index)
  end

  private def filter(query : String) : Nil
    # Keep the Table model and the Crystal backing array in sync, row by row.
    # Sending row_deleted/row_inserted is supported on all UIng platforms.
    @table.selection = UIng::Table::Selection.new([] of Int32)
    until @visible.empty?
      @visible.pop
      @model.row_deleted(@visible.size)
    end

    normalized = query.strip.downcase
    @icons.each do |icon|
      if normalized.empty? || icon.name.downcase.includes?(normalized)
        @visible << icon
        @model.row_inserted(@visible.size - 1)
      end
    end

    if @visible.empty?
      @current_index = -1
      @preview.image = nil
      @selected_name.text = "No matches"
      @constant.text = ""
      @status.text = "0 matches   •   #{@icons.size} total"
    else
      select_icon(0)
    end
  end
end

UIng.init
begin
  RadixIconViewer.new.run
ensure
  UIng.uninit
end
