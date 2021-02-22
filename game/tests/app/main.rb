require 'tests/test_helper.rb'

def test_player_is_rendered(args, assert)
  world = World.new
  world.add_entity :player, position: [2, 5]
  renderer = Renderer.new
  renderer.render_world(args, world)

  assert.equal! args.outputs.primitives.length, 1

  player_tile = Tile.for(:player)
  expected_attributes = { x: 2 * 24, y: 5 * 24 }.merge(
    player_tile.slice(:path, :source_x, :source_y, :source_w, :source_h, :w, :h, :r, :g, :b, :a)
  )
  assert.primitive_with!(expected_attributes, args.outputs.primitives)
end

def test_player_can_move(_args, assert)
  world = World.new
  player_id = world.add_entity :player, position: [2, 5]
  world.set_entity_property player_id, velocity: [1, 0]
  world.tick

  assert.equal! world.get_entity_property(player_id, :position), [3, 5]
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
