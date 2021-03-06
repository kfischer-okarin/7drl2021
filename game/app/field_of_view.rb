class FieldOfView
  include AttrRect

  attr_reader :x, :y, :w, :h, :from

  def self.closest_point_on_wall_to(wall, position:)
    x = if position.x < wall.grid_left
          wall.grid_left
        elsif position.x >= wall.grid_right
          wall.grid_right
        else
          position.x
        end
    y = if position.y < wall.grid_bottom
          wall.grid_bottom
        elsif position.y >= wall.grid_top
          wall.grid_top
        else
          position.y
        end
    [x, y]
  end

  def self.sort_by_distance_to(rects, position:)
    rects.sort_by { |rect|
      closest_point = closest_point_on_wall_to(rect, position: position)
      [(position.x - closest_point.x).abs, (position.y - closest_point.y).abs].max #.tap { |v| p [rect, closest_point, v] }
    }
  end

  def initialize(map)
    @map = map
    @x = 0
    @y = 0
    @w = map.size.x
    @h = map.size.y
    @visible = Array.build_2d(@w, @h, true)
    @debug_output = DebugOutput.new
  end

  def calculate(from:)
    @from = from
    @obstacles = FieldOfView.sort_by_distance_to(@map.obstacles, position: @from)
    @visible.fill_2d(true)
    calc_visible_positions
  end

  def visible?(x, y)
    (@visible[x] || [])[y]
  end

  private

  class DebugOutput
    def clear
      $args.debug.static_primitives.reject! { |primitive| primitive[:wall] }
      @process_order = 1
    end

    def render(obstacle)
      color = obstacle.w > obstacle.h ? { r: 255 } : { g: 255 }
      $args.debug.static_primitives << {
        x: obstacle.x * 24,
        y: obstacle.y * 24 + 72,
        w: obstacle.w * 24,
        h: obstacle.h * 24,
        wall: true
      }.merge(color).border
      $args.debug.static_primitives << {
        x: obstacle.x * 24,
        y: obstacle.y * 24 + 72 + 24,
        text: @process_order.to_s,
        wall: true
      }.merge(color).label
      @process_order += 1
    end
  end

  def calc_visible_positions
    @debug_output.clear if $args.debug.active?

    @obstacles.each do |obstacle|
      next unless visible?(obstacle.x, obstacle.y) # TODO: Fix

      @debug_output.render(obstacle) if $args.debug.active?

      next calc_pillar_shadow(obstacle) if obstacle.w == 1 && obstacle.h == 1

      if obstacle.w > 1 && obstacle.h == 1 && obstacle.y != @from.y
        obstacle_left = obstacle.grid_left
        obstacle_right = obstacle.grid_right

        dy = obstacle.y - @from.y
        dx_left = obstacle_left - @from.x
        dx_right = obstacle_right - @from.x
        y_step = dy.sign
        left_step = dx_left.sign
        right_step = dx_right.sign

        x_left = obstacle_left
        x_right = obstacle_right

        steps_needed = dy.abs
        x_left_progress = 0
        x_right_progress = 0
        y = obstacle.y + y_step
        while y >= 0 && y < @h
          x_left_progress += dx_left.abs
          while x_left_progress >= steps_needed
            x_left_progress -= steps_needed
            x_left = [x_left + left_step, 0].max
          end
          x_right_progress += dx_right.abs
          while x_right_progress >= steps_needed
            x_right_progress -= steps_needed
            x_right = [x_right + right_step, @w - 1].min
          end
          (x_left..x_right).each do |x|
            set_invisible(x, y)
          end
          y += y_step
        end
      elsif obstacle.h > 1 && obstacle.w == 1 && obstacle.x != @from.x
        obstacle_bottom = obstacle.grid_bottom
        obstacle_top = obstacle.grid_top

        dx = obstacle.x - @from.x
        dy_bottom = obstacle_bottom - @from.y
        dy_top = obstacle_top - @from.y
        x_step = dx.sign
        bottom_step = dy_bottom.sign
        top_step = dy_top.sign

        y_bottom = obstacle_bottom
        y_top = obstacle_top

        steps_needed = dx.abs
        y_bottom_progress = 0
        y_top_progress = 0
        x = obstacle.x + x_step
        while x >= 0 && x < @w
          y_bottom_progress += dy_bottom.abs
          while y_bottom_progress >= steps_needed
            y_bottom_progress -= steps_needed
            y_bottom = [y_bottom + bottom_step, 0].max
          end
          y_top_progress += dy_top.abs
          while y_top_progress >= steps_needed
            y_top_progress -= steps_needed
            y_top = [y_top + top_step, @h - 1].min
          end
          (y_bottom..y_top).each do |y|
            set_invisible(x, y)
          end
          x += x_step
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
end
