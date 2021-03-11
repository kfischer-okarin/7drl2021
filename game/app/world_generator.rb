class RNG
  def initialize
    @random = Random.new
  end

  # 0 .. max - 1
  def int(max)
    (@random.rand * max).floor
  end

  def int_between(min, max)
    int(max - min + 1) + min
  end

  def bool
    @random.rand >= 0.5
  end
end

class FloodFill
  attr_reader :result

  def initialize(map:, start_position:)
    @result = Set.new([start_position])
    @frontier = [start_position]
    @map = map
    calc
  end

  def calc
    until @frontier.empty?
      current = @frontier.shift
      neighbors = neighbors_of(current)
      @result.add_all neighbors
      @frontier.concat neighbors
    end
  end

  NEIGHBORS_OFFSETS = [
    [-1,  1], [0,  1], [1,  1],
    [-1,  0],          [1,  0],
    [-1, -1], [0, -1], [1, -1]
  ].map(&:freeze).freeze

  def neighbors_of(position)
    neighbor = [0, 0]
    [].tap { |result|
      NEIGHBORS_OFFSETS.each do |offset_x, offset_y|
        neighbor.x = position.x + offset_x
        neighbor.y = position.y + offset_y
        result << neighbor.dup unless @result.include?(neighbor) || @map.impassable?(neighbor)
      end
    }
  end
end

class CapsuleShapeRoom
  def initialize(length:, diameter:)
    @length = length
    @diameter = diameter
    @circle_radius = (@diameter / 2).ceil
    @side_wall_start = @circle_radius + 1
    @side_wall_end = @side_wall_start + @length - 1

    @right = @circle_radius * 2 + @length + 1
  end

  def wall_positions
    @wall_positions ||= Set.new.tap { |result|
      result.add_all side_wall(0)
      result.add_all side_wall(@diameter + 1)
      result.add_all capsule_ends
    }
  end

  def impassable?(position)
    wall_positions.include? position
  end

  def room_positions
    return @room_positions if @room_positions

    flood_fill = FloodFill.new(map: self, start_position: [1, @circle_radius])
    @room_positions = flood_fill.result
  end

  def side_wall(y)
    (@side_wall_start..@side_wall_end).map { |x| [x, y] }
  end

  def capsule_ends
    [].tap { |result|
      quarter_circle = calc_quarter_circle
      left_half_circle = quarter_circle + mirror_vertically(quarter_circle, at_y: (@diameter / 2) + 0.5)
      result.concat left_half_circle
      result.concat mirror_horizontally(left_half_circle, at_x: @right / 2)
    }
  end

  def mirror_vertically(positions, at_y:)
    mirror_max = (2 * at_y).to_i

    positions.map { |position|
      [position.x, mirror_max - position.y]
    }
  end

  def mirror_horizontally(positions, at_x:)
    mirror_max = (2 * at_x).to_i

    positions.map { |position|
      [mirror_max - position.x, position.y]
    }
  end

  def calc_quarter_circle
    [].tap { |result|
      center_coord = @diameter.odd? ? @circle_radius : @circle_radius + 0.5
      center = [center_coord, center_coord]
      radius_square = center_coord**2
      current = [@circle_radius, 0]
      result << current
      while current.y < @circle_radius
        candidates = [
          [current.x - 1, current.y],
          [current.x, current.y + 1]
        ]
        current = candidates.min_by { |position|
          ((position.x - center.x)**2 + (position.y - center.y)**2 - radius_square).abs
        }
        result << current
      end
    }
  end
end

class Structure
  attr_reader :w, :h, :tiles

  def initialize(w:, h:, tiles: nil)
    @w = w
    @h = h
    @tiles = tiles || Array.new(@w * @h)
  end

  def serialize
    "Structure.new(w: #{@w}, h: #{@h}, tiles: #{@tiles.inspect})"
  end

  alias_method :to_s, :serialize
  alias_method :inspect, :serialize

  def [](x, y)
    @tiles[tile_index(x, y)]
  end

  def []=(x, y, value)
    index = tile_index(x, y)
    return unless index

    @tiles[index] = value
  end

  def each(&block)
    enumerator = Enumerator.new do |yielder|
      @tiles.each_with_index do |tile, index|
        yielder.yield(tile, index % @w, index.idiv(@w))
      end
    end

    if block
      enumerator.each(&block)
    else
      enumerator
    end
  end

  def insert(area, at:)
    area.each do |value, x, y|
      self[at.x + x, at.y + y] = value
    end
  end

  def rotated_right_90
    Structure.new(w: @h, h: @w).tap { |result|
      each do |tile, x, y|
        result[y, @w - x - 1] = tile
      end
    }
  end

  def rotated_left_90
    Structure.new(w: @h, h: @w).tap { |result|
      each do |tile, x, y|
        result[@h - y - 1, x] = tile
      end
    }
  end

  def rotated_180
    Structure.new(w: @w, h: @h).tap { |result|
      each do |tile, x, y|
        result[@w - x - 1, @h - y - 1] = tile
      end
    }
  end

  def tile_index(x, y, w = @w)
    return if x.negative? || y.negative? || x >= @w || y >= @h

    y * w + x
  end
end

class WorldGenerator
  def initialize
    @rng = RNG.new
  end

  def generate
    World.new.tap { |world|
      # 10.times do
      #   pos = [@rng.int(20), @rng.int(20)]
      #   wall_length = @rng.int_between(3, 6)
      #   size = @rng.bool ? [1, wall_length] : [wall_length, 1]
      #   (pos + size).each_position do |position|
      #     next if world.entities_at(position).any? { |entity| entity[:block_movement] }

      #     world.add_entity type: :tree, position: position, block_movement: true
      #   end
      # end
      place_room world, generate_capsule, [-10, -10]
    }
  end

  def place_room(world, room, position)
    wall_prototype = { type: :wall, block_movement: true }
    room.wall_positions.each do |wall_position|
      placed_position = [wall_position.x + position.x, wall_position.y + position.y]
      next if world.has?({ type: :wall }, at: placed_position)

      world.add_entity wall_prototype.merge(position: placed_position)
    end
  end

  def generate_capsule
    CapsuleShapeRoom.new(length: 70, diameter: 40)
  end
end
