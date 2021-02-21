require 'lib/debug_mode.rb'
require 'lib/extra_keys.rb'
require 'lib/resources.rb'

require 'app/resources.rb'

class World
  def initialize
    @entities = {}
    @next_entity_id = 0
  end

  def entities
    @entities.values
  end

  def add_entity(type, attributes)
    id = next_entity_id
    @entities[id] = { type: type, id: id }.merge(attributes)
    id
  end

  def set_entity_property(id, attributes)
    @entities[id].merge!(attributes)
  end

  def get_entity_property(id, property)
    @entities[id][property]
  end

  def tick
    handle_movement
  end

  private

  def next_entity_id
    result = @next_entity_id
    @next_entity_id += 1
    result
  end

  def handle_movement
    entities.each do |entity|
      position = entity[:position]
      velocity = entity[:velocity]
      position.x += velocity.x
      position.y += velocity.y
    end
  end
end

class Renderer
  def render_world(args, world)
    world.entities.each do |entity|
      render_entity(args, entity)
    end
  end

  private

  def render_entity(args, entity)
    position = entity[:position]
    tile = Tile.for(entity[:type]).merge(x: position.x * 24, y: position.y * 24)
    args.outputs.primitives << tile
  end
end

class Tile
  def self.for(entity_type)
    {
      path: Resources.sprites.tileset, w: 24, h: 24,
      source_w: 24, source_h: 24, source_x: 0, source_y: 11 * 24,
      r: 218, g: 212, b: 94
    }
  end
end

def setup(args)
  world = World.new
  args.state.world = world
  world.add_entity :player, position: [2, 5]
  $renderer = Renderer.new
end

def tick(args)
  setup(args) if args.tick_count.zero?

  args.outputs.background_color = [0, 0, 0]
  $renderer.render_world(args, args.state.world)
end

$gtk.reset
