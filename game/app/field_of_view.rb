class FieldOfView
  attr_reader :visible_positions

  def initialize(map, from:, area:)
    @map = map
    @from = from
    @from_corners = corner_positions(from)
    @area = area
    @obstacle_sides = calc_obstacle_sides
    @visible_positions = calc_visible_positions
  end

  class HorizontalLine
    attr_reader :y, :x1, :x2

    def initialize(x1, x2, y:)
      @x1 = x1
      @x2 = x2
      @y = y
    end

    def intersection_with(other)
      return @y == other.y ? :identical : nil if other.is_a? HorizontalLine
      return intersection_with_vertical_line(other) if other.is_a? VerticalLine
    end

    def include_point?(point)
      point.y == @y && point.x >= @x1 && point.x <= @x2
    end

    private

    def intersection_with_vertical_line(other)
      (@y - other.y1) / (other.y2 - other.y1)
    end
  end

  class VerticalLine
    attr_reader :x, :y1, :y2

    def initialize(y1, y2, x:)
      @y1 = y1
      @y2 = y2
      @x = x
    end

    def intersection_with(other)
      return @x == other.x ? :identical : nil if other.is_a? VerticalLine
      return intersection_with_horizontal_line(other) if other.is_a? HorizontalLine
    end

    def include_point?(point)
      point.x == @x && point.y >= @y1 && point.y <= @y2
    end

    private

    def intersection_with_horizontal_line(other)
      (@x - other.x1) / (other.x2 - other.x1)
    end
  end

  class Line
    def self.from_points(point1, point2)
      return VerticalLine.new(point1.y, point2.y, x: point1.x) if point1.x == point2.x
      return HorizontalLine.new(point1.x, point2.x, y: point1.y) if point1.y == point2.y

      new(point1, point2)
    end

    def initialize(point1, point2)
      @x, @y = point1
      @dx = point2.x - point1.x
      @dy = point2.y - point1.y
    end

    def intersection_with(other)
      return intersection_with_horizontal_line(other) if other.is_a? HorizontalLine
      return intersection_with_vertical_line(other) if other.is_a? VerticalLine

      raise 'General line-line intersection not implemented yet'
    end

    private

    def intersection_with_horizontal_line(other)
      # x + a * dx = ox1 + result * (ox2 - ox1)
      # y + a * dy = oy
      # => a = (oy - y) / dy
      # => x + (oy - y) * dx / dy = ox1 + result * (ox2 - ox1)
      # => ((x - ox1) + (oy - y) * dx / dy) / (ox2 - ox1)
      ((@x - other.x1) + (other.y - @y) * (@dx / @dy)) / (other.x2 - other.x1)
    end

    def intersection_with_vertical_line(other)
      # Reverse from above
      ((@y - other.y1) + (other.x - @x) * (@dy / @dx)) / (other.y2 - other.y1)
    end
  end

  private

  def corner_positions(position)
    [-0.5, 0.5].flat_map { |offset_x|
      [-0.5, 0.5].map { |offset_y|
        [position.x + offset_x, position.y + offset_y]
      }
    }
  end

  ZERO_ONE = (0..1).freeze

  def unobstructed_connection?(pos1, pos2)
    line = Line.from_points(pos1, pos2)

    @obstacle_sides.none? { |obstacle_side|
      next if obstacle_side.include_point? pos2

      intersection = line.intersection_with(obstacle_side)
      intersection == :identical || ZERO_ONE.include?(intersection)
    }
  end

  def visible?(position)
    return true if position == @from

    target_corners = corner_positions(position)

    @from_corners.any? { |from_corner|
      target_corners.any? { |target_corner|
        unobstructed_connection?(from_corner, target_corner)
      }
    }
  end

  def calc_visible_positions
    Set.new.tap { |result|
      @area.each_position do |position|
        result << position if visible?(position)
      end
    }
  end

  def square_sides(position)
    [
      HorizontalLine.new(position.x - 0.5, position.x + 0.5, y: position.y - 0.5),
      HorizontalLine.new(position.x - 0.5, position.x + 0.5, y: position.y + 0.5),
      VerticalLine.new(position.y - 0.5, position.y + 0.5, x: position.x - 0.5),
      VerticalLine.new(position.y - 0.5, position.y + 0.5, x: position.x + 0.5)
    ]
  end

  def calc_obstacle_sides
    @map.blocking_positions_in(@area).flat_map { |position|
      square_sides(position)
    }
  end
end
