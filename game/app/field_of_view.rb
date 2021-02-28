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
