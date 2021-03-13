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

  def int_in(range)
    int_between(range.min, range.max)
  end

  def sample_from(array)
    index = int_between(0, array.size - 1)
    array[index]
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

class Pathfinding
  def initialize(map, from:, to:)
    @map = map
    @from = from
    @to = to

    find_path
  end

  def path_exists?
    @path_exists
  end

  private

  def find_path
    frontier = PriorityQueue.new
    frontier.insert @from, 0
    came_from = {}
    cost_so_far = { @from => 0 }

    until frontier.empty?
      current = frontier.pop

      break if current == @to

      @map.neighbors_of(current).each do |neighbor|
        next unless @map.passable?(current, neighbor.vector_sub(current))

        new_cost = cost_so_far[current] + move_cost(current, neighbor)
        next unless !cost_so_far.key?(neighbor) || new_cost < cost_so_far[neighbor]

        cost_so_far[neighbor] = new_cost
        priority = new_cost + move_cost_heuristic(neighbor)
        frontier.insert neighbor, priority
        came_from[neighbor] = current
      end
    end

    @path_exists = cost_so_far.key? @to

    # @path = calc_path(to, came_from)
  end

  def move_cost(from, to)
    1
  end

  def move_cost_heuristic(position)
    (@to.x - position.x).abs + (@to.y - position.y).abs
  end
end

module Shape
  class Capsule
    def initialize(length:, diameter:)
      @length = length
      @diameter = diameter
      @circle_radius = (@diameter / 2).ceil
      @side_wall_start = @circle_radius + 1
      @side_wall_end = @side_wall_start + @length - 1

      @right = @circle_radius * 2 + @length + 1
    end

    def positions
      @positions ||= Set.new.tap { |result|
        result.add_all side_wall(0)
        result.add_all side_wall(@diameter + 1)
        result.add_all capsule_ends
      }
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

  class Rectangle
    attr_reader :w, :h

    def initialize(w:, h:)
      @w = w
      @h = h
    end

    def positions
      @positions ||= Set.new.tap { |result|
        (0...@w).each do |x|
          result << [x, 0]
          result << [x, @h - 1]
        end
        (0...@h).each do |y|
          result << [0, y]
          result << [@w - 1, y]
        end
      }
    end
  end
end

class Structure
  attr_reader :w, :h, :tiles

  def initialize(w:, h:, tiles: nil)
    @w = w
    @h = h
    @tiles = tiles || Array.new(@w * @h)
  end

  def to_h
    { w: @w, h: @h, tiles: @tiles }
  end

  def self.deserialize(hash)
    new(w: hash[:w], h: hash[:h], tiles: hash[:tiles])
  end

  def serialize
    to_h.merge(deserialize_class: self.class.name).inspect
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

  def insert(structure, at:)
    structure.each do |value, x, y|
      self[at.x + x, at.y + y] = value
    end
  end

  def set_all(positions, tile, offset: nil)
    offset_x, offset_y = offset || [0, 0]
    positions.each do |position|
      self[position.x + offset_x, position.y + offset_y] = tile
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

class PathfindableWorld
  def initialize(world)
    @world = world
  end

  def passable?(from_position, to_position)
    @world.entities_at(to_position).none? { |entity|
      entity[:block_movement]
    }
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
        result << neighbor.dup
      end
    }
  end
end

class WorldGenerator
  def initialize
    @rng = RNG.new
    @world = World.new
  end

  def generate
    place_stage_walls

    @world.add_entity type: :player, player: true, position: [5, 20], velocity: [0, 0]

    30.times do
      place_slum_structure
    end

    @world
  end

  def place_stage_walls
    wall_shape = Shape::Capsule.new(length: 70, diameter: 40)
    place_if_not_exists(wall_shape.positions, PROTOTYPES[:wall])
  end

  def place_slum_structure
    size = [@rng.int_between(7, 10), @rng.int_between(7, 10)]
    rect = find_rect(size, inside_rect: [0, 0, 110, 40]) do |result|
      @world.entities_with(:block_movement).inside_rect(result).none? &&
        @world.entities_with(:player).inside_rect(result).none?
    end
    return unless rect

    shape = Shape::Rectangle.new(w: size.x, h: size.y)
    positions = shape.positions.map { |position|
      [position.x + rect.x, position.y + rect.y]
    }
    placed_entity_ids = place_if_not_exists(positions, PROTOTYPES[:big_wood_block])
    pathfinding = Pathfinding.new(PathfindableWorld.new(@world), from: [5, 20], to: [105, 20])
    return if pathfinding.path_exists?

    placed_entity_ids.each do |entity_id|
      @world.delete entity_id
    end
  end

  def find_rect(size, inside_rect:, &condition)
    retries = 0
    loop do
      x = @rng.int_between(inside_rect.grid_left, inside_rect.grid_right - size.x - 1)
      y = @rng.int_between(inside_rect.grid_bottom, inside_rect.grid_top - size.y - 1)

      result_rect = [x, y, size.x, size.y]
      return result_rect if condition.call(result_rect)

      retries += 1
      return if retries >= 10
    end
  end

  def place_if_not_exists(positions, prototype)
    [].tap { |placed_positions|
      positions.each do |position|
        next if @world.has?({ type: prototype[:type] }, at: position)

        @world.add_entity prototype.merge(position: position)
        placed_positions << position
      end
    }
  end

  PROTOTYPES = {
    wall: { type: :wall, block_movement: true },
    big_wood_block: { type: :big_wood_block, block_movement: true },
    small_wood_block: { type: :small_wood_block, block_movement: true }
  }.freeze
end
