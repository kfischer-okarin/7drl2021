class FieldOfView
  attr_reader :visible_positions

  def initialize(map, from:, area:)
    @map = map
    @from = from
    @area = area
    @obstacles = sort_by_distance(map.blocking_positions_in(@area))
    @visible_positions = calc_visible_positions
  end

  private

  def covered_positions(obstacle)
    return ((obstacle.x + 1)...@area.right).map { |x| [x, @from.y] } if obstacle.x > @from.x
    return (@area.left...obstacle.x).map { |x| [x, @from.y] } if obstacle.x < @from.x
    return ((obstacle.y + 1)...@area.top).map { |y| [@from.x, y] } if obstacle.y > @from.y
    return (@area.bottom...obstacle.y).map { |y| [@from.x, y] } if obstacle.y < @from.y

    []
  end

  def calc_visible_positions
    Set.new(*@area.each_position).tap { |result|
      @obstacles.each do |obstacle|
        next unless result.include? obstacle

        covered_positions(obstacle).each do |covered_position|
          result.delete covered_position
        end
      end
    }
  end

  def sort_by_distance(positions)
    positions.sort_by { |position|
      [(@from.x - position.x).abs, (@from.y - position.y).abs].min
    }
  end
end
