class FieldOfView
  include AttrRect
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

      dx = obstacle.x - @from.x
      dy = obstacle.y - @from.y

      if dy.zero?
        if dx.positive?
          ((obstacle.x + 1)...@w).each do |x|
            set_invisible(x, @from.y)
          end
        elsif dx.negative?
          (0...obstacle.x).each do |x|
            set_invisible(x, @from.y)
          end
        end
      elsif dx.zero?
        if dy.positive?
          ((obstacle.y + 1)...@h).each do |y|
            set_invisible(@from.x, y)
          end
        elsif dy.negative?
          (0...obstacle.y).each do |y|
            set_invisible(@from.x, y)
          end
        end
      elsif dx.abs == 1 && dy.abs == 1
        pos = [obstacle.x + dx, obstacle.y + dy]
        while pos.inside_grid_rect? self
          set_invisible(pos.x, pos.y)
          pos.x += dx
          pos.y += dy
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
