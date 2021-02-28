class LineOfSight
  attr_reader :visible_positions

  def initialize(map, from:, area:)
    @map = map
    @from = from
    @area = area
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

    private

    def intersection_with_horizontal_line(other)
      (@x - other.x1) / (other.x2 - other.x1)
    end
  end

  private

  def visible?(position)
    true
  end

  def calc_visible_positions
    Set.new.tap { |result|
      @area.each_position do |position|
        result << position if visible?(position)
      end
    }
  end
end
