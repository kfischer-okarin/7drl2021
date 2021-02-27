class Array
  def vector_add(other)
    map_with_index { |value, index| value + other[index] }
  end

  def zero?
    all?(&:zero?)
  end
end
