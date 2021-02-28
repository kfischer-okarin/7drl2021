class Array
  def vector_add(other)
    map_with_index { |value, index| value + other[index] }
  end

  def zero?
    all?(&:zero?)
  end

  def each_position(&block)
    enumerator = Enumerator.new do |yielder|
      x = self[0]
      y = self[1]
      while y < self[3]
        while x < self[2]
          yielder << [x, y]
          x += 1
        end
        x = self[0]
        y += 1
      end
    end

    block ? enumerator.each(&block) : enumerator
  end
end
