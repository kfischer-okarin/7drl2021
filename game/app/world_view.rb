class Tile
  class << self
    def at_position(position)
      {
        path: Resources.sprites.tileset, w: 24, h: 24,
        source_w: 24, source_h: 24, source_x: position.x * 24, source_y: position.y * 24
      }
    end

    def letter_tile_position(letter)
      case letter
      when 'A'..'O'
        x = letter.ord - 'A'.ord + 1
        [x, 11]
      when 'P'..'Z'
        x = letter.ord - 'P'.ord
        [x, 10]
      when 'a'..'o'
        x = letter.ord - 'a'.ord + 1
        [x, 9]
      when 'p'..'z'
        x = letter.ord - 'p'.ord
        [x, 8]
      when '.'
        [14, 13]
      else
        [0, 15]
      end
    end

    def for_letter(letter)
      at_position(letter_tile_position(letter))
    end

    def for(entity_type)
      case entity_type
      when :player
        at_position([0, 11]).merge(r: 218, g: 212, b: 94)
      when :tree
        at_position([5, 15]).merge(r: 52, g: 101, b: 36)
      when :wall
        at_position([3, 13]).merge(r: 78, g: 74, b: 78)
      when :floor
        for_letter('.').merge(r: 255, g: 255, b: 255)
      end
    end
  end
end

class RenderedWorld
  attr_reader :world

  def initialize(world)
    @world = world
  end

  def tile_at(position)
    entities = @world.entities_at(position)
    if entities.empty?
      Tile.for(:floor)
    else
      Tile.for(entities[0][:type])
    end
  end

  def changes_in_rect?(rect)
    @world.changed_positions.any? { |position| position.inside_grid_rect? rect }
  end
end

class VisibleWorld
  attr_writer :updated

  def initialize(rendered_world, size:)
    @rendered_world = rendered_world
    @rect = [0, 0, size.x, size.y]
    @origin_x = 0
    @origin_y = 0
    @field_of_view = FieldOfView.new(self)
    @updated = false
  end

  def size
    [@rect.w, @rect.h]
  end

  def tile_at(position)
    return unless @field_of_view.visible?(position.x - @origin_x, position.y - @origin_y)

    @rendered_world.tile_at(position)
  end

  def changes_in_rect?(rect)
    @updated || @rendered_world.changes_in_rect?(rect)
  end

  def update(player_position, origin)
    return if @player_position == player_position && origin == [@origin_x, @origin_y] && !@rendered_world.changes_in_rect?(@rect)

    @player_position = player_position
    @origin_x = @rect.x = origin.x
    @origin_y = @rect.y = origin.y
    @field_of_view.calculate(from: relative_position(@player_position))
    @updated = true
  end

  def relative_position(position)
    [position.x - @origin_x, position.y - @origin_y]
  end

  def merge_to_horizontal_wall(obstacle, obstacles)
    rect = [obstacle.x, obstacle.y, 1, 1]
    used_obstacles = [obstacle]
    while obstacles.include? [rect.x - 1, rect.y]
      used_obstacles << [rect.x - 1, rect.y]
      rect.x -= 1
      rect.w += 1
    end
    while obstacles.include? [rect.grid_right + 1, rect.y]
      used_obstacles << [rect.grid_right + 1, rect.y]
      rect.w += 1
    end

    return [nil, nil] unless rect.w > 1

    [rect, used_obstacles]
  end

  def merge_to_vertical_wall(obstacle, obstacles)
    rect = [obstacle.x, obstacle.y, 1, 1]
    used_obstacles = [obstacle]
    while obstacles.include? [rect.x, rect.y - 1]
      used_obstacles << [rect.x, rect.y - 1]
      rect.y -= 1
      rect.h += 1
    end
    while obstacles.include? [rect.x, rect.grid_top + 1]
      used_obstacles << [rect.x, rect.grid_top + 1]
      rect.h += 1
    end

    return [nil, nil] unless rect.h > 1

    [rect, used_obstacles]
  end

  def merge_obstacles(obstacles)
    in_horizontal_wall = Set.new
    in_vertical_wall = Set.new
    [].tap { |result|
      obstacles.each do |obstacle|
        unless in_horizontal_wall.include? obstacle
          merged, used_obstacles = merge_to_horizontal_wall(obstacle, obstacles)

          if merged
            result << merged
            in_horizontal_wall.add_all used_obstacles
          end
        end

        unless in_vertical_wall.include? obstacle
          merged, used_obstacles = merge_to_vertical_wall(obstacle, obstacles)

          if merged
            result << merged
            in_vertical_wall.add_all used_obstacles
          end
        end
        next if in_vertical_wall.include?(obstacle) || in_horizontal_wall.include?(obstacle)

        result << [obstacle.x, obstacle.y, 1, 1]
      end
    }
  end

  def obstacles
    [].tap { |result|
      obstacles = Set.new
      @rendered_world.world.entities_with(:block_movement).each { |entity|
        position = entity[:position]
        obstacles << relative_position(position) if position.inside_grid_rect? @rect
      }
      merge_obstacles(obstacles).each do |obstacle|
        result << obstacle
      end
    }
  end
end

class WorldView < TilemapView
  def initialize(world, size:)
    super(
      tilemap: world,
      name: :map_view,
      rect: [0, 0, size.x, size.y],
      tile_size: 24,
      chunk_size: [8, 8]
    )
  end

  def center_on(position)
    self.origin = [position.x - @size.x.idiv(2), position.y - @size.y.idiv(2)]
  end
end
