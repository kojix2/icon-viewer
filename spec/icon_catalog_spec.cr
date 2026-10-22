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
    }.each do |collection, name, variant|
      icon = icons.find { |entry| entry.collection == collection && entry.name == name }
      icon.should_not be_nil
      icon.not_nil!.variant.should eq(variant)
    end
  end
end
