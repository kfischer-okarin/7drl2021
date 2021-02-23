def test_velocity_causes_move(_args, assert)
  world = World.new
  player_id = world.add_entity :player, position: [2, 5], velocity: [0, 0]
  world.set_entity_property player_id, velocity: [1, 0]
  world.tick

  assert.equal! world.get_entity_property(player_id, :position), [3, 5]
end
