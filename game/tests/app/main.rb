require 'tests/test_helper.rb'

def test_player_is_rendered(args, assert)
  world = World.new
  world.add_entity :player, position: [2, 5]
  renderer = Renderer.new
  renderer.render_world(args, world)

  assert.equal! args.outputs.primitives.length, 1

  player_tile = Tile.for(:player)
  expected_attributes = { x: 2 * 24, y: 5 * 24 }.merge(
    TestHelper.tile_attributes(player_tile)
  ).merge(
    player_tile.slice(:r, :g, :b, :a)
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

def test_text_can_be_rendered(args, assert)
  renderer = Renderer.new
  renderer.render_string(args, 'Hello', x: 100, y: 100)

  letter_tile = Tile.for_letter('H')
  expected_attributes = { x: 100, y: 100 }.merge(TestHelper.tile_attributes(letter_tile))
  assert.primitive_with!(expected_attributes, args.outputs.primitives)

  letter_tile = Tile.for_letter('e')
  expected_attributes = { x: 100 + 1 * 16, y: 100 }.merge(TestHelper.tile_attributes(letter_tile))
  assert.primitive_with!(expected_attributes, args.outputs.primitives)

  letter_tile = Tile.for_letter('l')
  expected_attributes = { x: 100 + 2 * 16, y: 100 }.merge(TestHelper.tile_attributes(letter_tile))
  assert.primitive_with!(expected_attributes, args.outputs.primitives)

  letter_tile = Tile.for_letter('l')
  expected_attributes = { x: 100 + 3 * 16, y: 100 }.merge(TestHelper.tile_attributes(letter_tile))
  assert.primitive_with!(expected_attributes, args.outputs.primitives)

  letter_tile = Tile.for_letter('o')
  expected_attributes = { x: 100 + 4 * 16, y: 100 }.merge(TestHelper.tile_attributes(letter_tile))
  assert.primitive_with!(expected_attributes, args.outputs.primitives)
end

$gtk.reset 100
$gtk.log_level = :off
