class FieldOfView
  def initialize(map, from:, area:)
    @map = map
    @from = from
    @area = area
    @obstacles = sort_by_distance(map.blocking_positions_in(@area))
    @visible = (0...@area.w).map {
      (0...@area.h).map { true }
    }
    calc_visible_positions
  end

  def visible?(x, y)
    (@visible[x - @area.x] || [])[y - @area.y]
  end

  private

  def calc_visible_positions
    @obstacles.each do |obstacle|
      next unless visible?(obstacle.x, obstacle.y)

      if obstacle.x > @from.x
        ((obstacle.x + 1)...@area.right).each do |x|
          set_invisible(x, @from.y)
        end
      elsif obstacle.x < @from.x
        (@area.left...obstacle.x).each do |x|
          set_invisible(x, @from.y)
        end
      elsif obstacle.y > @from.y
        ((obstacle.y + 1)...@area.top).each do |y|
          set_invisible(@from.x, y)
        end
      elsif obstacle.y < @from.y
        (@area.bottom...obstacle.y).each do |y|
          set_invisible(@from.x, y)
        end
      end
    end
  end

  def set_invisible(x, y)
    @visible[x - @area.x][y - @area.y] = false
  end

  def sort_by_distance(positions)
    positions.sort_by { |position|
      [(@from.x - position.x).abs, (@from.y - position.y).abs].min
    }
  end
end
