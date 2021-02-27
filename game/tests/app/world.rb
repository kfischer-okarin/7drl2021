require 'tests/test_helper.rb'

def test_velocity_causes_move(_args, assert)
  world = World.new
  player_id = world.add_entity :player, position: [2, 5], velocity: [0, 0]
  world.set_entity_property player_id, velocity: [1, 0]
  world.tick

  assert.equal! world.get_entity_property(player_id, :position), [3, 5]
  assert.equal! world.changed_positions, Set.new([2, 5], [3, 5])
end

def test_entity_cannot_move_into_blocking_entities(_args, assert)
  world = World.new
  world.add_entity :tree, position: [3, 5], block_movement: true
  player_id = world.add_entity :player, position: [2, 5], velocity: [0, 0]
  world.set_entity_property player_id, velocity: [1, 0]
  world.tick

  assert.equal! world.get_entity_property(player_id, :position), [2, 5]
  assert.equal! world.changed_positions, Set.new
end

def test_world_can_be_serialized_deserialized(_args, assert)
  world = World.new
  world.add_entity :player, position: [2, 5], velocity: [0, 0]
  world.add_entity :tree, position: [3, 7]
  world.add_entity :tree, position: [7, 12]

  serialized = world.serialize
  restored_world = eval(serialized) # rubocop:disable Security/Eval

  assert.true! restored_world.object_id != world.object_id
  assert.equal! restored_world.entities, world.entities
  assert.equal! restored_world.next_entity_id, world.next_entity_id
end

$gtk.reset 100
$gtk.log_level = :off
