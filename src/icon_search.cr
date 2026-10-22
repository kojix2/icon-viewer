# Normalize both CamelCase catalog names and common human search spellings.
module IconSearch
  def self.normalize(value : String) : String
    value.downcase.gsub(/[^\p{L}\p{N}]/, "")
  end

  def self.tokens(query : String) : Array(String)
    query.split.map { |word| normalize(word) }.reject(&.empty?)
  end

  def self.matches?(normalized_name : String, tokens : Array(String)) : Bool
    tokens.all? { |token| normalized_name.includes?(token) }
  end
end
