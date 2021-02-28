class LineOfSight
  attr_reader :visible_positions

  def initialize(map, from:, area:)
    @map = map
    @from = from
    @area = area
    @visible_positions = calc_visible_positions
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
