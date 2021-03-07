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

  class Line
    attr_reader :x, :y

    attr_accessor :progress

    def initialize(start, dx:, dy:)
      @x = start.x
      @y = start.y
      @dx = dx
      @dy = dy
      @x_step = @dx.sign
      @y_step = @dy.sign
      @progress = 0
    end

    def inc_y
      @progress += @dx.abs
      steps_needed = @dy.abs
      while @progress >= steps_needed
        @progress -= steps_needed
        @x += @x_step
      end
      @y += @y_step
    end

    def inc_x
      @progress += @dy.abs
      steps_needed = @dx.abs
      while @progress >= steps_needed
        @progress -= steps_needed
        @y += @y_step
      end
      @x += @x_step
    end
  end

  def calc_visible_positions
    @debug_output.clear if $args.debug.active?

    @obstacles.each do |obstacle|
      next unless obstacle.each_position.any? { |x, y| visible?(x, y) }

      @debug_output.render(obstacle) if $args.debug.active?

      next calc_pillar_shadow(obstacle) if obstacle.w == 1 && obstacle.h == 1

      # TODO: Remove w/h > 1 and remove pillar shadow
      if obstacle.h == 1
        if @from.y == obstacle.y
          wall_part = @from.x < obstacle.x ? obstacle : [obstacle.grid_right, obstacle.y, 1, 1]
          calc_vertical_wall_shadow(wall_part)
        else
          calc_horizontal_wall_shadow(obstacle)
        end
      end

      if obstacle.w == 1
        if @from.x == obstacle.x
          wall_part = @from.y < obstacle.y ? obstacle : [obstacle.x, obstacle.grid_top, 1, 1]
          calc_horizontal_wall_shadow(wall_part)
        else
          calc_vertical_wall_shadow(obstacle)
        end
      end
    end
  end

  def calc_horizontal_wall_shadow(obstacle)
    dy = obstacle.y - @from.y

    dx_left = obstacle.grid_left - @from.x
    left_line_start = [obstacle.grid_left - 1, obstacle.y]
    left_line_start.x += 1 if dx_left.positive? # Special case for diagonal left
    left_line = Line.new(left_line_start, dx: dx_left, dy: dy)
    left_line.progress -= 1 if dx_left.positive? # Special case for diagonal left

    dx_right = obstacle.grid_right - @from.x
    right_line_start = [obstacle.grid_right + 1, obstacle.y]
    right_line_start.x -= 1 if dx_right.negative? # Special case for diagonal right
    right_line = Line.new(right_line_start, dx: dx_right, dy: dy)
    right_line.progress -= 1 if dx_right.negative? # Special case for diagonal right

    while left_line.y > 0 && left_line.y < @h - 1
      left_line.inc_y
      right_line.inc_y

      shadow_start = [(left_line.x + 1), 0].max
      shadow_end = [(right_line.x - 1), @w - 1].min
      (shadow_start..shadow_end).each do |x|
        set_invisible(x, left_line.y)
      end
    end
  end

  def calc_vertical_wall_shadow(obstacle)
    dx = obstacle.x - @from.x

    dy_bottom = obstacle.grid_bottom - @from.y
    bottom_line_start = [obstacle.x, obstacle.grid_bottom - 1]
    bottom_line_start.y += 1 if dy_bottom.positive? # Special case for diagonal bottom
    bottom_line = Line.new(bottom_line_start, dx: dx, dy: dy_bottom)
    bottom_line.progress -= 1 if dy_bottom.positive? # Special case for diagonal bottom

    dy_top = obstacle.grid_top - @from.y
    top_line_start = [obstacle.x, obstacle.grid_top + 1]
    top_line_start.y -= 1 if dy_top.negative? # Special case for diagonal top
    top_line = Line.new(top_line_start, dx: dx, dy: dy_top)
    top_line.progress -= 1 if dy_top.negative? # Special case for diagonal top

    while bottom_line.x > 0 && bottom_line.x < @w - 1
      bottom_line.inc_x
      top_line.inc_x

      shadow_start = [(bottom_line.y + 1), 0].max
      shadow_end = [(top_line.y - 1), @h - 1].min
      (shadow_start..shadow_end).each do |y|
        set_invisible(bottom_line.x, y)
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
