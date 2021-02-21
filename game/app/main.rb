require 'lib/debug_mode.rb'
require 'lib/extra_keys.rb'
require 'lib/resources.rb'

require 'app/resources.rb'

class World
  attr_reader :entities

  def initialize
    @entities = []
  end

  def add_entity(type, attributes)
    @entities << { type: type }.merge(attributes)
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
