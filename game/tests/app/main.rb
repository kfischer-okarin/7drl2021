require 'tests/test_helper.rb'

def test_player_is_rendered(args, assert)
  world = World.new
  world.add_entity :player, position: [2, 5]
  renderer = Renderer.new
  renderer.render_world(args, world)

  player_tile = Tile.for(:player)
  expected_attributes = TestHelper.tile_attributes(player_tile, :r, :g, :b, :a, x: 2 * 24, y: 5 * 24)
  assert.primitive_with!(expected_attributes, args.outputs.primitives)
end

def test_world_view_can_be_rendered(args, assert)
  world = World.new
  world.add_entity :player, position: [12, 13]
  world_view = WorldView.new(world, w: 5, h: 5)
  world_view.origin = [0, 0]
  renderer = Renderer.new
  renderer.render_world(args, world_view)

  assert.equal! args.outputs.primitives.length, 0

  world_view.origin = [10, 10]
  renderer.render_world(args, world_view)

  player_tile = Tile.for(:player)
  expected_attributes = TestHelper.tile_attributes(player_tile, :r, :g, :b, :a, x: 2 * 24, y: 3 * 24)
  assert.primitive_with!(expected_attributes, args.outputs.primitives)
end

def test_world_view_can_center_on_position(args, assert)
  world = World.new
  world_view = WorldView.new(world, w: 5, h: 5)
  world_view.origin = [0, 0]

  world_view.center_on([12, 15])

  assert.equal! [10, 13], world_view.origin
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

def test_text_can_be_rendered(args, assert)
  renderer = Renderer.new
  renderer.render_string(args, 'Hello', x: 100, y: 100)

  letter_tile = Tile.for_letter('H')
  expected_attributes = TestHelper.tile_attributes(letter_tile, x: 100, y: 100)
  assert.primitive_with!(expected_attributes, args.outputs.primitives)

  letter_tile = Tile.for_letter('e')
  expected_attributes = TestHelper.tile_attributes(letter_tile, x: 100 + 1 * 16, y: 100)
  assert.primitive_with!(expected_attributes, args.outputs.primitives)

  letter_tile = Tile.for_letter('l')
  expected_attributes = TestHelper.tile_attributes(letter_tile, x: 100 + 2 * 16, y: 100)
  assert.primitive_with!(expected_attributes, args.outputs.primitives)

  letter_tile = Tile.for_letter('l')
  expected_attributes = TestHelper.tile_attributes(letter_tile, x: 100 + 3 * 16, y: 100)
  assert.primitive_with!(expected_attributes, args.outputs.primitives)

  letter_tile = Tile.for_letter('o')
  expected_attributes = TestHelper.tile_attributes(letter_tile, x: 100 + 4 * 16, y: 100)
  assert.primitive_with!(expected_attributes, args.outputs.primitives)
end

$gtk.reset 100
$gtk.log_level = :off
