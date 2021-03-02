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
      when :floor
        for_letter('.').merge(r: 255, g: 255, b: 255)
      end
    end
  end
end

# TODO: Add VisibleWorldWrapper around RenderedWorld
class RenderedWorld
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

class WorldView < TilemapView
  def initialize(world, size:)
    super(
      tilemap: RenderedWorld.new(world),
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
