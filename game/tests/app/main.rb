require 'tests/test_helper.rb'

def test_render_world(args, assert)
  world = World.new
  world.add_entity :player, position: [12, 13]
  world_view = WorldView.new(world, size: [5, 5])
  world_view.origin = [10, 10]
  world_view.tick(args)
  args.outputs.primitives << world_view

  player_tile = Tile.for(:player)
  floor_tile = Tile.for(:floor)
  (0...5).each do |x|
    (0...5).each do |y|
      expected_attributes = if x == 2 && y == 2
                              TestHelper.tile_attributes(floor_tile, x: x * 24, y: y * 24 + 72)
                            else
                              TestHelper.tile_attributes(player_tile, :r, :g, :b, :a, x: 2 * 24, y: 3 * 24)
                            end
      assert.primitive_was_rendered!(expected_attributes, args)
    end
  end
end

def test_world_view_can_center_on_position(_args, assert)
  world = World.new
  world_view = WorldView.new(world, size: [5, 5])

  world_view.center_on([12, 15])

  assert.equal! world_view.origin, [10, 13]
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
  assert.primitive_was_rendered!(expected_attributes, args)

  letter_tile = Tile.for_letter('e')
  expected_attributes = TestHelper.tile_attributes(letter_tile, x: 100 + 1 * 16, y: 100)
  assert.primitive_was_rendered!(expected_attributes, args)

  letter_tile = Tile.for_letter('l')
  expected_attributes = TestHelper.tile_attributes(letter_tile, x: 100 + 2 * 16, y: 100)
  assert.primitive_was_rendered!(expected_attributes, args)

  letter_tile = Tile.for_letter('l')
  expected_attributes = TestHelper.tile_attributes(letter_tile, x: 100 + 3 * 16, y: 100)
  assert.primitive_was_rendered!(expected_attributes, args)

  letter_tile = Tile.for_letter('o')
  expected_attributes = TestHelper.tile_attributes(letter_tile, x: 100 + 4 * 16, y: 100)
  assert.primitive_was_rendered!(expected_attributes, args)
end

$gtk.reset 100
$gtk.log_level = :off
