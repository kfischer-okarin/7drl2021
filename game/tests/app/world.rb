require 'tests/test_helper.rb'

def test_velocity_causes_move(args, assert)
  world = World.new World.build_empty_state(args)
  player_id = world.add_entity position: [2, 5], velocity: [0, 0]
  world.set_entity_property player_id, velocity: [1, 0]
  world.tick

  assert.equal! world.get_entity_property(player_id, :position), [3, 5]
  assert.contains_exactly! world.changed_positions, [[2, 5], [3, 5]]
end

def test_entity_cannot_move_into_blocking_entities(args, assert)
  world = World.new World.build_empty_state(args)
  world.add_entity position: [3, 5], block_movement: true
  player_id = world.add_entity position: [2, 5], velocity: [0, 0]
  world.set_entity_property player_id, velocity: [1, 0]
  world.tick

  assert.equal! world.get_entity_property(player_id, :position), [2, 5]
  assert.equal! world.changed_positions.size, 0
end

def test_world_entities_with(args, assert)
  world = World.new World.build_empty_state(args)
  id1 = world.add_entity position: [2, 5], velocity: [0, 0]
  world.add_entity position: [3, 7]
  id2 = world.add_entity position: [7, 12], velocity: [2, 1]

  assert.contains_exactly! world.entities_with(:velocity), [
    { id: id1, position: [2, 5], velocity: [0, 0] },
    { id: id2, position: [7, 12], velocity: [2, 1] }
  ]
end

def test_world_entities_with_inside_rect(args, assert)
  world = World.new World.build_empty_state(args)
  id1 = world.add_entity position: [2, 5]
  id2 = world.add_entity position: [3, 7]
  world.add_entity position: [7, 12]

  assert.contains_exactly! world.entities_with(:position).inside_rect([2, 5, 6, 3]), [
    { id: id1, position: [2, 5] },
    { id: id2, position: [3, 7] }
  ]
end

def test_world_set_get_property(args, assert)
  world = World.new World.build_empty_state(args)
  id = world.add_entity hp: 23

  world.set_entity_property(id, hp: 25)

  assert.equal! world.get_entity_property(id, :hp), 25
  assert.contains_exactly! world.entities_with(:hp), [
    { id: id, hp: 25 }
  ]
end

def test_world_entities_at(args, assert)
  world = World.new World.build_empty_state(args)
  id1 = world.add_entity position: [1, 1], type: :player
  id2 = world.add_entity position: [1, 1], type: :item
  world.add_entity position: [3, 7], type: :enemy

  assert.contains_exactly! world.entities_at([1, 1]), [
    { id: id1, position: [1, 1], type: :player },
    { id: id2, position: [1, 1], type: :item }
  ]
end

def test_world_has(args, assert)
  world = World.new World.build_empty_state(args)
  world.add_entity position: [1, 1], type: :player

  assert.true! world.has?({ type: :player }, at: [1, 1])
  assert.false! world.has?({ type: :player }, at: [1, 2])
end

$gtk.reset 100
$gtk.log_level = :off
