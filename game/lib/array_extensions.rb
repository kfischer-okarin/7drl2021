class Array
  def vector_add(other)
    map_with_index { |value, index| value + other[index] }
  end

  def zero?
    all?(&:zero?)
  end

  def self.build_2d(size1, size2, default_value = nil)
    (0...size1).map {
      Array.new(size2, default_value)
    }
  end

  def fill_2d(value)
    each do |sub_array|
      sub_array.fill(value)
    end
  end

  def inside_grid_rect?(rect)
    x >= rect.x && x < rect.right && y >= rect.y && y < rect.top
  end
end
