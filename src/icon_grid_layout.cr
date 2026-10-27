# Geometry shared by drawing, hit testing, and keyboard navigation.
struct IconGridLayout
  CELL_WIDTH  = 96
  CELL_HEIGHT = 88
  PADDING     =  8

  getter count : Int32
  getter columns : Int32

  def initialize(@count : Int32, @columns : Int32 = 6)
    raise ArgumentError.new("count must be nonnegative") if @count < 0
    raise ArgumentError.new("columns must be positive") if @columns < 1
  end

  def width : Int32
    PADDING * 2 + @columns * CELL_WIDTH
  end

  def height : Int32
    PADDING * 2 + {1, (@count + @columns - 1) // @columns}.max * CELL_HEIGHT
  end

  def position(index : Int32) : {Int32, Int32}
    {PADDING + index % @columns * CELL_WIDTH, PADDING + index // @columns * CELL_HEIGHT}
  end

  def index_at(x : Float64, y : Float64) : Int32?
    return nil if x < PADDING || y < PADDING
    col = ((x - PADDING) / CELL_WIDTH).floor.to_i
    row = ((y - PADDING) / CELL_HEIGHT).floor.to_i
    return nil if col >= @columns
    index = row * @columns + col
    index < @count ? index : nil
  end

  # The native clip can describe a partial repaint, not the entire viewport.
  def visible_indices(y : Float64, height : Float64) : Range(Int32, Int32)
    first_row = {0, ((y - PADDING) / CELL_HEIGHT).floor.to_i}.max
    last_row = {0, ((y + height - PADDING) / CELL_HEIGHT).ceil.to_i}.max
    {first_row * @columns, @count}.min...{last_row * @columns, @count}.min
  end

  def move(index : Int32, direction : Symbol) : Int32?
    return nil if @count == 0
    target = case direction
             when :left  then index - 1
             when :right then index + 1
             when :up    then index - @columns
             when :down  then index + @columns
             when :home  then 0
             when :end   then @count - 1
             else             return nil
             end
    target.clamp(0, @count - 1)
  end
end
