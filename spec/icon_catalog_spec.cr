require "spec"
require "../src/icon_catalog"

describe IconCatalog do
  it "registers the new collections with useful size and style variants" do
    icons = IconCatalog.all
    {
      {"Radix", "Gear", ""},
      {"Fluent", "Add20Filled", "20 Filled"},
      {"Octicons", "Heart16", "16"},
      {"Eva", "Heart24Outline", "24 Outline"},
      {"Ionic", "Heart24Sharp", "24 Sharp"},
      {"Ionic", "LogoGithub32", "32 Logos"},
      {"Fluent", "GaugeRotate016Filled", "16 Filled"},
      {"Fluent", "NumberCircle016Regular", "16 Regular"},
      {"Fluent", "Fps3016Filled", "16 Filled"},
      {"Ionic", "LogoCss324", "24 Logos"},
      {"Ionic", "LogoHtml532", "32 Logos"},
    }.each do |collection, name, variant|
      icon = icons.find! { |entry| entry.collection == collection && entry.name == name }
      icon.variant.should eq(variant)
    end
    lockup = icons.find! { |entry| entry.collection == "Octicons" && entry.name == "LockupGithub16" }
    lockup.width.should eq(68)
    lockup.height.should eq(16)
  end
end
