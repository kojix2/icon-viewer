require "spec"
require "../src/icon_variants"

describe IconVariants do
  it "builds Fluent choices from size and style labels" do
    options = IconVariants.options(["20 Regular", "20 Filled", "16 Light", "20 Filled", "24 Color"])
    options.should eq(["All variants", "16 Light", "20 Filled", "20 Regular", "24 Color"])
    options.index("20 Regular").should eq(3)
  end

  it "sorts sizes numerically" do
    IconVariants.options(["100 Regular", "24 Regular", "8 Regular"]).should eq(
      ["All variants", "8 Regular", "24 Regular", "100 Regular"]
    )
  end

  it "provides only All variants for a collection without variants" do
    IconVariants.options(["", ""]).should eq(["All variants"])
    IconVariants.options([] of String).should eq(["All variants"])
  end
end
