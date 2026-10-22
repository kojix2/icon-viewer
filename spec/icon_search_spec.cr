require "spec"
require "../src/icon_search"

describe IconSearch do
  it "matches human spellings against CamelCase names" do
    name = IconSearch.normalize("ArrowLeft20Regular")
    ["arrow left", "ARROW-LEFT", "arrow_left", "left arrow", "arrow 20 regular"].each do |query|
      IconSearch.matches?(name, IconSearch.tokens(query)).should be_true
    end
  end

  it "requires every search term" do
    IconSearch.matches?(IconSearch.normalize("ArrowLeft20Regular"), IconSearch.tokens("arrow filled")).should be_false
  end

  it "treats whitespace and separators as an empty search" do
    ["", "  \t ", "--- ___"].each do |query|
      IconSearch.matches?("calendar", IconSearch.tokens(query)).should be_true
    end
  end

  it "does not broaden an unknown non-Latin query to all icons" do
    IconSearch.matches?("calendar", IconSearch.tokens("カレンダー")).should be_false
  end
end
