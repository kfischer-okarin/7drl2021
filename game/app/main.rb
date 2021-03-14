require 'lib/debug_mode.rb'
require 'lib/extra_keys.rb'
require 'lib/resources.rb'
require 'lib/rect_extensions.rb'
require 'lib/array_extensions.rb'
require 'lib/set.rb'
require 'lib/priority_queue.rb'
require 'lib/tilemap_view/require.rb'
require 'lib/hoard.rb'

require 'app/resources.rb'
require 'app/field_of_view.rb'
require 'app/world.rb'
require 'app/world_view.rb'
require 'app/world_generator.rb'
require 'app/data_manager.rb'
require 'app/structure_editor.rb'

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

class Game
  def tick(args)
    setup(args) if args.tick_count.zero?

    world = args.state.world
    if @input.any?(args)
      @input.apply_to(args, world)
      world.tick
      handle_player_position_update(world, args.state.player_id)
    end

    args.outputs.background_color = [0, 0, 0]
    @world_view.tick(args)
    args.outputs.primitives << @world_view
    world.changed_positions.clear
    @visible_world.updated = false
    world.messages[0..2].each_with_index do |message, index|
      @renderer.render_string(args, message, x: 24, y: index * 24, a: 255 - 90 * index)
    end

    if args.inputs.keyboard.key_down.f6
      $scenes.unshift StructureEditor.new
    end
  end

  private

  def setup(args)
    generator = WorldGenerator.new
    world = generator.generate
    args.state.world = world
    args.state.player_id = world.entities_with(:player).to_a[0][:id]
    @visible_world = VisibleWorld.new(RenderedWorld.new(world), size: [40, 27])
    @world_view = WorldView.new(@visible_world, size: @visible_world.size)
    @world_view.x = 0
    @world_view.y = 3 * 24
    handle_player_position_update(world, args.state.player_id)
    @renderer = Renderer.new
    @input = Input.new(args.state.player_id)
  end

  def handle_player_position_update(world, player_id)
    player_position = world.get_entity_property(player_id, :position)
    @world_view.center_on(player_position)
    @visible_world.update(player_position, @world_view.origin)
  end
end

def tick(args)
  $scenes ||= [Game.new]
  $scenes[0].tick(args)
end

$gtk.reset
