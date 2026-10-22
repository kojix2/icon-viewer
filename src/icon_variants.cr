module IconVariants
  ALL = "All variants"

  def self.options(variants : Enumerable(String)) : Array(String)
    sorted = variants.reject(&.empty?).uniq.sort_by do |variant|
      {variant.split(' ', 2).first.to_i, variant}
    end
    [ALL] + sorted
  end
end
