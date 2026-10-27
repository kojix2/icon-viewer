require "spec"
require "../src/icon_grid_layout"

describe IconGridLayout do
  it "lays out every result beyond the old 256-icon page boundary" do
    layout = IconGridLayout.new(10_001, 6)
    layout.position(256).should eq({392, 3704})
    layout.position(10_000).should eq({392, 146_616})
    layout.height.should eq(146_712)
  end

  it "maps cell centers to the same indices used for drawing" do
    [4, 6, 8, 10].each do |columns|
      layout = IconGridLayout.new(513, columns)
      513.times do |index|
        x, y = layout.position(index)
        layout.index_at(x + 48.0, y + 44.0).should eq(index)
      end
    end
  end

  it "ignores outer padding and empty cells in the last row" do
    layout = IconGridLayout.new(7, 6)
    layout.index_at(7.9, 20.0).should be_nil
    layout.index_at(20.0, 7.9).should be_nil
    layout.index_at(584.0, 20.0).should be_nil
    layout.index_at(104.0, 96.0).should be_nil
    layout.index_at(8.0, 184.0).should be_nil
    layout.index_at(8.0, 96.0).should eq(6)
  end

  it "limits repaint work to intersecting rows, including partial rows" do
    layout = IconGridLayout.new(10_000, 6)
    layout.visible_indices(8.0, 88.0).to_a.should eq((0...6).to_a)
    layout.visible_indices(90.0, 20.0).to_a.should eq((0...12).to_a)
    layout.visible_indices(3704.0, 88.0).to_a.should eq((252...258).to_a)
    layout.visible_indices(200_000.0, 300.0).should be_empty
  end

  it "never paints nonexistent entries in a partial last row or empty grid" do
    IconGridLayout.new(7).visible_indices(96.0, 500.0).to_a.should eq([6])
    empty = IconGridLayout.new(0)
    empty.visible_indices(0.0, 500.0).should be_empty
    empty.index_at(20.0, 20.0).should be_nil
    empty.height.should be > 0
  end

  it "moves by rows and clamps navigation at both ends" do
    layout = IconGridLayout.new(13, 6)
    layout.move(7, :up).should eq(1)
    layout.move(7, :down).should eq(12)
    layout.move(0, :left).should eq(0)
    layout.move(12, :right).should eq(12)
    layout.move(7, :home).should eq(0)
    layout.move(7, :end).should eq(12)
    IconGridLayout.new(0).move(-1, :right).should be_nil
  end

  it "rejects invalid geometry" do
    expect_raises(ArgumentError) { IconGridLayout.new(1, 0) }
    expect_raises(ArgumentError) { IconGridLayout.new(-1) }
  end
end
