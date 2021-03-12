require 'tests/test_helper.rb'

def test_capsule(_args, assert)
  shape = Shape::Capsule.new(length: 4, diameter: 5)
  assert.contains_exactly! shape.positions, TestHelper.as_positions([
    ' xxxxxxxxxx ',
    'xx        xx',
    'x          x',
    'x          x',
    'x          x',
    'xx        xx',
    ' xxxxxxxxxx '
  ]), 'length 4 diameter 5'

  shape = Shape::Capsule.new(length: 3, diameter: 5)
  assert.contains_exactly! shape.positions, TestHelper.as_positions([
    ' xxxxxxxxx ',
    'xx       xx',
    'x         x',
    'x         x',
    'x         x',
    'xx       xx',
    ' xxxxxxxxx '
  ]), 'length 3 diameter 5'

  shape = Shape::Capsule.new(length: 3, diameter: 4)
  assert.contains_exactly! shape.positions, TestHelper.as_positions([
    ' xxxxxxx ',
    'xx     xx',
    'x       x',
    'x       x',
    'xx     xx',
    ' xxxxxxx '
  ]), 'length 3 diameter 4'
end

def test_rectangle(args, assert)
  shape = Shape::Rectangle.new(w: 3, h: 4)
  assert.contains_exactly! shape.positions, TestHelper.as_positions([
    'xxx',
    'x x',
    'x x',
    'xxx'
  ]), 'w 3 h 4'

  shape = Shape::Rectangle.new(w: 4, h: 3)
  assert.contains_exactly! shape.positions, TestHelper.as_positions([
    'xxxx',
    'x  x',
    'xxxx'
  ]), 'w 4 h 3'
end

def test_structure_each(_args, assert)
  s = Structure.new(w: 2, h: 2)
  s[0, 0] = :a
  s[1, 0] = :b
  s[0, 1] = :c
  s[1, 1] = :d

  assert.equal! s.each.to_a, [
    [:a, 0, 0], [:b, 1, 0],
    [:c, 0, 1], [:d, 1, 1]
  ]
end

def test_structure_rotated_right_90(_args, assert)
  s = Structure.new(w: 3, h: 2, tiles: %i[a b c d e f])

  rotated = s.rotated_right_90

  assert.equal! rotated.tiles, %i[
    c f
    b e
    a d
  ]
end

def test_structure_rotated_left_90(_args, assert)
  s = Structure.new(w: 3, h: 2, tiles: %i[a b c d e f])

  rotated = s.rotated_left_90

  assert.equal! rotated.tiles, %i[
    d a
    e b
    f c
  ]
end

def test_structure_rotated_right_180(_args, assert)
  s = Structure.new(w: 3, h: 2, tiles: %i[a b c d e f])

  rotated = s.rotated_180

  assert.equal! rotated.tiles, %i[
    f e d
    c b a
  ]
end

def test_structure_insert(_args, assert)
  s = Structure.new(w: 3, h: 3)
  s2 = Structure.new(w: 2, h: 2, tiles: %i[a b c d])

  s.insert(s2, at: [1, 1])

  assert.equal! s.tiles, [
    nil, nil, nil,
    nil, :a, :b,
    nil, :c, :d
  ]
end

$gtk.reset 100
$gtk.log_level = :off
