class FieldOfView
  include RectExtensions

  attr_reader :x, :y, :w, :h

  def initialize(map)
    @map = map
    @x = 0
    @y = 0
    @w = map.size.x
    @h = map.size.y
    @visible = Array.build_2d(@w, @h, true)
  end

  def calculate(from:)
    @from = from
    @obstacles = sort_by_distance(@map.obstacles)
    @visible.fill_2d(true)
    calc_visible_positions
  end

  def visible?(x, y)
    (@visible[x] || [])[y]
  end

  private

  def calc_visible_positions
    @obstacles.each do |obstacle|
      next unless visible?(obstacle.x, obstacle.y)

      if obstacle.x > @from.x
        ((obstacle.x + 1)...@w).each do |x|
          set_invisible(x, @from.y)
        end
      elsif obstacle.x < @from.x
        (0...obstacle.x).each do |x|
          set_invisible(x, @from.y)
        end
      elsif obstacle.y > @from.y
        ((obstacle.y + 1)...@h).each do |y|
          set_invisible(@from.x, y)
        end
      elsif obstacle.y < @from.y
        (0...obstacle.y).each do |y|
          set_invisible(@from.x, y)
        end
      end
    end
  end

  def set_invisible(x, y)
    @visible[x][y] = false
  end

  def sort_by_distance(positions)
    positions.sort_by { |position|
      [(@from.x - position.x).abs, (@from.y - position.y).abs].min
    }
  end
end
