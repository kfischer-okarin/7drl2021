module RectExtensions
  def each_position(&block)
    enumerator = Enumerator.new do |yielder|
      x = self.x
      y = self.x
      while y < self.h
        while x < self.w
          yielder << [x, y]
          x += 1
        end
        x = self.x
        y += 1
      end
    end

    block ? enumerator.each(&block) : enumerator
  end
end
