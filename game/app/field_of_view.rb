class FieldOfView
  include AttrRect

  attr_reader :x, :y, :w, :h, :from

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

      next calc_pillar_shadow(obstacle) if obstacle.w == 1 && obstacle.h == 1

      if obstacle.w > 1 && obstacle.h == 1 && obstacle.y != @from.y
        obstacle_left = obstacle.grid_left
        obstacle_right = obstacle.grid_right

        dy = obstacle.y - @from.y
        dx_left = obstacle_left - @from.x
        dx_right = obstacle_right - @from.x
        x_left = obstacle_left
        x_right = obstacle_right
        y = obstacle.y + dy
        while y >= 0 && y < @h
          x_left = [x_left + dx_left, 0].max
          x_right = [x_right + dx_right, @w - 1].min
          (x_left..x_right).each do |x|
            set_invisible(x, y)
          end
          y += dy
        end
      elsif obstacle.h > 1 && obstacle.w == 1 && obstacle.x != @from.x
        obstacle_bottom = obstacle.grid_bottom
        obstacle_top = obstacle.grid_top

        dx = obstacle.x - @from.x
        dy_bottom = obstacle_bottom - @from.y
        dx_top = obstacle_top - @from.y
        y_bottom = obstacle_bottom
        y_top = obstacle_top
        x = obstacle.x + dx
        while x >= 0 && x < @w
          y_bottom = [y_bottom + dy_bottom, 0].max
          y_top = [y_top + dx_top, @h - 1].min
          (y_bottom..y_top).each do |y|
            set_invisible(x, y)
          end
          x += dx
        end
      end
    end
  end

  def set_invisible(x, y)
    @visible[x][y] = false
  end

  def calc_pillar_shadow(obstacle)
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
    else
      pos = [obstacle.x + dx, obstacle.y + dy]
      while pos.inside_grid_rect? self
        set_invisible(pos.x, pos.y)
        pos.x += dx
        pos.y += dy
      end
    end
  end

  def sort_by_distance(positions)
    # TODO: Improve for rects
    positions.sort_by { |position|
      [(@from.x - position.x).abs, (@from.y - position.y).abs].min
    }
  end
end
