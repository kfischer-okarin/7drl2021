require 'lib/debug_mode.rb'
require 'lib/extra_keys.rb'
require 'lib/resources.rb'

require 'app/resources.rb'
require 'app/world.rb'

class WorldView
  attr_reader :origin

  def initialize(world, w:, h:)
    @world = world
    @w = w
    @h = h
    self.origin = [0, 0]
  end

  def origin=(value)
    @origin = value
    @bounds = [@origin.x, @origin.y, @w, @h]
  end

  def entities
    (0...@w).map { |x|
      (0...@h).map { |y|
        position = [x + @origin.x, y + @origin.y]
        at_position = @world.entities_at(position)
        at_position.empty? ? { type: :floor, position: position } : at_position
      }
    }.flatten
  end

  def position_of(entity)
    world_position = @world.position_of(entity)
    [world_position.x - @origin.x, world_position.y - @origin.y]
  end

  def center_on(position)
    self.origin = [position.x - @w.idiv(2), position.y - @h.idiv(2)]
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
    Tile.for(entity[:type])
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
  args.state.player_id = world.add_entity :player, position: [2, 5], velocity: [0, 0]
  20.times do
    world.add_entity :tree, position: [(rand * 20).floor, (rand * 20).floor]
  end
  $world_view = WorldView.new(world, w: 40, h: 30)
  $world_view.center_on(world.position_of(world.entity(args.state.player_id)))
  $renderer = Renderer.new
  $input = Input.new(args.state.player_id)
end

def tick(args)
  setup(args) if args.tick_count.zero?

  world = args.state.world
  if $input.any?(args)
    $input.apply_to(args, world)
    world.tick
    $world_view.center_on(world.position_of(world.entity(args.state.player_id)))
  end

  args.outputs.background_color = [0, 0, 0]
  $renderer.render_world(args, $world_view)
  $renderer.render_string(args, 'You find a red gemstone', x: 24, y: 24)
end

$gtk.reset
