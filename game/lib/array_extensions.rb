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

  def update_with_index_2d
    each_with_index do |sub_array, index1|
      (0...sub_array.size).each do |index2|
        sub_array[index2] = yield sub_array[index2], index1, index2
      end
    end
  end
end
