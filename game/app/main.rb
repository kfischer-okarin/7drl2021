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

  def position_of(entity)
    entity[:position]
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
  def initialize
    @entity_tiles = {}
  end

  def render_world(args, world)
    world.entities.each do |entity|
      render_entity(args, entity, world.position_of(entity))
    end
  end

  def render_string(args, string, attributes)
    args.outputs.primitives << string.chars.map_with_index { |char, index|
      Tile.for_letter(char).merge(attributes).tap { |tile|
        tile.x += index * 16
      }
    }
  end

  private

  def render_entity(args, entity, position)
    tile = entity_tile(entity).update(x: position.x * 24, y: position.y * 24)
    args.outputs.primitives << tile
  end

  def entity_tile(entity)
    @entity_tiles[entity[:id]] ||= Tile.for(entity[:type])
  end
end

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
      else
        [0, 15]
      end
    end

    def for_letter(letter)
      at_position(letter_tile_position(letter))
    end

    def for(entity_type)
      at_position([0, 11]).merge(r: 218, g: 212, b: 94)
    end
  end
end

class Input
  def initialize(player_id)
    @player_id = player_id
  end

  def any?(args)
    args.inputs.keyboard.key_down.truthy_keys.any?
  end

  def apply_to(args, world)
    velocity = calc_velocity_from_input(args.inputs)
    world.set_entity_property(@player_id, velocity: velocity)
  end

  private

  def calc_velocity_from_input(gtk_inputs)
    key_down = gtk_inputs.keyboard.key_down

    [key_down.left_right, key_down.up_down]
  end
end

def setup(args)
  world = World.new
  args.state.world = world
  player_id = world.add_entity :player, position: [2, 5]
  $renderer = Renderer.new
  $input = Input.new(player_id)
end

def tick(args)
  setup(args) if args.tick_count.zero?

  world = args.state.world
  if $input.any?(args)
    $input.apply_to(args, world)
    world.tick
  end

  args.outputs.background_color = [0, 0, 0]
  $renderer.render_world(args, world)
  $renderer.render_string(args, 'You find a red gemstone', x: 24, y: 24)
end

$gtk.reset
