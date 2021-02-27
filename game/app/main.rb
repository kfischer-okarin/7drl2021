require 'lib/debug_mode.rb'
require 'lib/extra_keys.rb'
require 'lib/resources.rb'
require 'lib/set.rb'
require 'lib/tilemap_view/require.rb'

require 'app/resources.rb'
require 'app/world.rb'
require 'app/world_view.rb'

class Renderer
  def render_string(args, string, attributes)
    args.outputs.primitives << string.chars.map_with_index { |char, index|
      Tile.for_letter(char).merge(attributes).tap { |tile|
        tile.x += index * 16
      }
    }
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
    world.add_entity :tree, position: [(rand * 20).floor, (rand * 20).floor], block_movement: true
  end
  $world_view = WorldView.new(world, size: [40, 27])
  $world_view.x = 0
  $world_view.y = 3 * 24
  $world_view.center_on(world.get_entity_property(args.state.player_id, :position))
  $renderer = Renderer.new
  $input = Input.new(args.state.player_id)
end

def tick(args)
  setup(args) if args.tick_count.zero?

  world = args.state.world
  if $input.any?(args)
    $input.apply_to(args, world)
    world.tick
    $world_view.center_on(world.get_entity_property(args.state.player_id, :position))
  end

  args.outputs.background_color = [0, 0, 0]
  $world_view.tick(args)
  args.outputs.primitives << $world_view
  world.changed_positions.clear
  world.messages[0..2].each_with_index do |message, index|
    $renderer.render_string(args, message, x: 24, y: index * 24, a: 255 - 90 * index)
  end
end

$gtk.reset
