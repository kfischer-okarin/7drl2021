module RectExtensions
  def inside_grid_rect?(other_rect)
    grid_left >= other_rect.grid_left && grid_right <= other_rect.grid_right &&
      grid_bottom >= other_rect.grid_bottom && grid_top <= other_rect.grid_top
  end

  def each_position(&block)
    enumerator = Enumerator.new do |yielder|
      x = grid_left
      y = grid_bottom
      while y <= grid_top
        while x <= grid_right
          yielder << [x, y]
          x += 1
        end
        x = grid_left
        y += 1
      end
    end

    block ? enumerator.each(&block) : enumerator
  end
end

module AttrRect
  def grid_left
    @x
  end

  def grid_right
    @x + @w - 1
  end

  def grid_bottom
    @y
  end

  def grid_top
    @y + @h - 1
  end

  include RectExtensions
end

class Array
  def grid_left
    self[0]
  end

  def grid_right
    if size == 2
      self[0]
    else
      self[0] + self[2] - 1
    end
  end

  def grid_bottom
    self[1]
  end

  def grid_top
    if size == 2
      self[1]
    else
      self[1] + self[3] - 1
    end
  end

  include RectExtensions
end
