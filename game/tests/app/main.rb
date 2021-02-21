def test_player_is_rendered(args, assert)
  world = World.new
  world.add_entity :player, position: [2, 5]
  renderer = Renderer.new
  renderer.render_world(args, world)

  assert.equal! args.outputs.primitives.length, 1

  primitive = args.outputs.primitives[0]
  player_tile = Tile.for(:player)

  assert.equal! primitive.x, 2 * 24
  assert.equal! primitive.y, 5 * 24
  %i[path source_x source_y source_w source_h w h r g b a].each do |property|
    assert.equal! primitive.send(property), player_tile.send(property),
                  "Expected rendered tile to have same #{property} as player tile but it was different!"
  end
end

def test_player_can_move(_args, assert)
  world = World.new
  player_id = world.add_entity :player, position: [2, 5]
  world.set_entity_property player_id, velocity: [1, 0]
  world.tick

  assert.equal! world.get_entity_property(player_id, :position), [3, 5]
end

module TestHelper
  class << self
    def clear_keyboard(args)
      args.inputs.keyboard.key_down.clear
    end

    def simulate_keypress(args, *keys)
      clear_keyboard(args)
      args.inputs.keyboard.key_down.set keys
    end
  end
end

def test_input_sets_player_velocity(args, assert)
  world = World.new
  player_id = world.add_entity :player, position: [2, 5]
  input = Input.new(player_id)

  TestHelper.simulate_keypress(args, :left)
  input.apply_to(args, world)

  assert.equal! world.get_entity_property(player_id, :velocity), [-1, 0]

  TestHelper.simulate_keypress(args, :right)
  input.apply_to(args, world)

  assert.equal! world.get_entity_property(player_id, :velocity), [1, 0]

  TestHelper.simulate_keypress(args, :up)
  input.apply_to(args, world)

  assert.equal! world.get_entity_property(player_id, :velocity), [0, 1]

  TestHelper.simulate_keypress(args, :down)
  input.apply_to(args, world)

  assert.equal! world.get_entity_property(player_id, :velocity), [0, -1]

  TestHelper.clear_keyboard(args)
  input.apply_to(args, world)

  assert.equal! world.get_entity_property(player_id, :velocity), [0, 0]
end

$gtk.reset 100
$gtk.log_level = :off
