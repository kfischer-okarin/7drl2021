require 'tests/test_helper.rb'

def test_capsule_room_wall_positions(_args, assert)
  room = CapsuleShapeRoom.new(length: 4, diameter: 5)
  assert.contains_exactly! room.wall_positions, TestHelper.as_positions([
    ' xxxxxxxxxx ',
    'xx        xx',
    'x          x',
    'x          x',
    'x          x',
    'xx        xx',
    ' xxxxxxxxxx '
  ]), 'length 4 diameter 5'

  room = CapsuleShapeRoom.new(length: 3, diameter: 5)
  assert.contains_exactly! room.wall_positions, TestHelper.as_positions([
    ' xxxxxxxxx ',
    'xx       xx',
    'x         x',
    'x         x',
    'x         x',
    'xx       xx',
    ' xxxxxxxxx '
  ]), 'length 3 diameter 5'

  room = CapsuleShapeRoom.new(length: 3, diameter: 4)
  assert.contains_exactly! room.wall_positions, TestHelper.as_positions([
    ' xxxxxxx ',
    'xx     xx',
    'x       x',
    'x       x',
    'xx     xx',
    ' xxxxxxx '
  ]), 'length 3 diameter 4'
end

def test_capsule_room_room_positions(_args, assert)
  room = CapsuleShapeRoom.new(length: 4, diameter: 5)
  assert.contains_exactly! room.room_positions, TestHelper.as_positions([
    '            ',
    '  xxxxxxxx  ',
    ' xxxxxxxxxx ',
    ' xxxxxxxxxx ',
    ' xxxxxxxxxx ',
    '  xxxxxxxx  ',
    '            '
  ]), 'length 4 diameter 5'

  room = CapsuleShapeRoom.new(length: 3, diameter: 5)
  assert.contains_exactly! room.room_positions, TestHelper.as_positions([
    '           ',
    '  xxxxxxx  ',
    ' xxxxxxxxx ',
    ' xxxxxxxxx ',
    ' xxxxxxxxx ',
    '  xxxxxxx  ',
    '           '
  ]), 'length 3 diameter 5'

  room = CapsuleShapeRoom.new(length: 3, diameter: 4)
  assert.contains_exactly! room.room_positions, TestHelper.as_positions([
    '         ',
    '  xxxxx  ',
    ' xxxxxxx ',
    ' xxxxxxx ',
    '  xxxxx  ',
    '         '
  ]), 'length 3 diameter 4'
end

$gtk.reset 100
$gtk.log_level = :off
