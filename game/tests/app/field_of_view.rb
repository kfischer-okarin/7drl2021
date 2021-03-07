require 'tests/test_helper.rb'

module FieldOfViewTest
  class Map
    attr_reader :size

    def initialize(size)
      @size = size
      @blocking_sight = Set.new
    end

    def block_sight(position)
      @blocking_sight << (position.length == 2 ? [position.x, position.y, 1, 1] : position)
    end

    def obstacles
      @blocking_sight.to_a
    end

    def visibility_map(field_of_view)
      (0...field_of_view.h).map { |y_from_top|
        y = field_of_view.h - y_from_top - 1
        (0...field_of_view.w).map { |x|
          if field_of_view.visible?(x, y)
            if @blocking_sight.any? { |obstacle| [x, y].inside_grid_rect?(obstacle) }
              'o'
            elsif field_of_view.from == [x, y]
              '@'
            else
              ' '
            end
          else
            'x'
          end
        }.join
      }.join("\n")
    end
  end

  def self.map3x3_pillar_center
    map = Map.new([3, 3])
    map.block_sight [1, 1]

    [map, FieldOfView.new(map)]
  end
end

def test_fov_without_obstacle(_args, assert)
  map = FieldOfViewTest::Map.new([3, 3])
  field_of_view = FieldOfView.new(map)
  field_of_view.calculate(from: [0, 0])

  assert.equal! map.visibility_map(field_of_view), [
    '   ',
    '   ',
    '@  '
  ].join("\n")
end

def test_fov_directly_left_of_pillar(_args, assert)
  map, field_of_view = FieldOfViewTest.map3x3_pillar_center
  field_of_view.calculate(from: [0, 1])

  assert.equal! map.visibility_map(field_of_view), [
    '   ',
    '@ox',
    '   '
  ].join("\n")
end

def test_fov_directly_down_of_pillar(_args, assert)
  map, field_of_view = FieldOfViewTest.map3x3_pillar_center
  field_of_view.calculate(from: [1, 0])

  assert.equal! map.visibility_map(field_of_view), [
    ' x ',
    ' o ',
    ' @ '
  ].join("\n")
end

def test_fov_directly_right_of_pillar(_args, assert)
  map, field_of_view = FieldOfViewTest.map3x3_pillar_center
  field_of_view.calculate(from: [2, 1])

  assert.equal! map.visibility_map(field_of_view), [
    '   ',
    'xo@',
    '   '
  ].join("\n")
end

def test_fov_directly_up_of_pillar(_args, assert)
  map, field_of_view = FieldOfViewTest.map3x3_pillar_center
  field_of_view.calculate(from: [1, 2])

  assert.equal! map.visibility_map(field_of_view), [
    ' @ ',
    ' o ',
    ' x '
  ].join("\n")
end

def test_fov_directly_down_left_of_pillar(_args, assert)
  map, field_of_view = FieldOfViewTest.map3x3_pillar_center
  field_of_view.calculate(from: [0, 0])

  assert.equal! map.visibility_map(field_of_view), [
    '  x',
    ' o ',
    '@  '
  ].join("\n")
end

def test_fov_directly_down_right_of_pillar(_args, assert)
  map, field_of_view = FieldOfViewTest.map3x3_pillar_center
  field_of_view.calculate(from: [2, 0])

  assert.equal! map.visibility_map(field_of_view), [
    'x  ',
    ' o ',
    '  @'
  ].join("\n")
end

def test_fov_directly_up_left_of_pillar(_args, assert)
  map, field_of_view = FieldOfViewTest.map3x3_pillar_center
  field_of_view.calculate(from: [0, 2])

  assert.equal! map.visibility_map(field_of_view), [
    '@  ',
    ' o ',
    '  x'
  ].join("\n")
end

def test_fov_directly_up_right_of_pillar(_args, assert)
  map, field_of_view = FieldOfViewTest.map3x3_pillar_center
  field_of_view.calculate(from: [2, 2])

  assert.equal! map.visibility_map(field_of_view), [
    '  @',
    ' o ',
    'x  '
  ].join("\n")
end

def test_fov_two_or_more_steps_away_from_pillar(_args, assert)
  map = FieldOfViewTest::Map.new([10, 10])
  map.block_sight [2, 2]
  field_of_view = FieldOfView.new(map)
  field_of_view.calculate(from: [1, 0])

  assert.equal! map.visibility_map(field_of_view), [
    '          ',
    '     x    ',
    '          ',
    '    x     ',
    '          ',
    '   x      ',
    '          ',
    '  o       ',
    '          ',
    ' @        '
  ].join("\n")
end

def test_fov_directly_down_of_wall(_args, assert)
  map = FieldOfViewTest::Map.new([5, 5])
  map.block_sight [1, 1, 2, 1]
  field_of_view = FieldOfView.new(map)
  field_of_view.calculate(from: [1, 0])

  assert.equal! map.visibility_map(field_of_view), [
    ' xxxx',
    ' xxxx',
    ' xxx ',
    ' oo  ',
    ' @   '
  ].join("\n")
end

def test_fov_directly_up_of_wall(_args, assert)
  map = FieldOfViewTest::Map.new([5, 5])
  map.block_sight [1, 3, 2, 1]
  field_of_view = FieldOfView.new(map)
  field_of_view.calculate(from: [1, 4])

  assert.equal! map.visibility_map(field_of_view), [
    ' @   ',
    ' oo  ',
    ' xxx ',
    ' xxxx',
    ' xxxx'
  ].join("\n")
end

def test_fov_directly_left_of_wall(_args, assert)
  map = FieldOfViewTest::Map.new([5, 5])
  map.block_sight [1, 1, 1, 2]
  field_of_view = FieldOfView.new(map)
  field_of_view.calculate(from: [0, 1])

  assert.equal! map.visibility_map(field_of_view), [
    '   xx',
    '  xxx',
    ' oxxx',
    '@oxxx',
    '     '
  ].join("\n")
end

def test_fov_directly_right_of_wall(_args, assert)
  map = FieldOfViewTest::Map.new([5, 5])
  map.block_sight [3, 1, 1, 2]
  field_of_view = FieldOfView.new(map)
  field_of_view.calculate(from: [4, 1])

  assert.equal! map.visibility_map(field_of_view), [
    'xx   ',
    'xxx  ',
    'xxxo ',
    'xxxo@',
    '     '
  ].join("\n")
end

def test_fov_two_or_more_steps_away_from_wall_vertical(_args, assert)
  map = FieldOfViewTest::Map.new([10, 10])
  map.block_sight [3, 3, 4, 1]
  field_of_view = FieldOfView.new(map)
  field_of_view.calculate(from: [4, 0])

  assert.equal! map.visibility_map(field_of_view), [
    ' xxxxxxxxx',
    '  xxxxxxxx',
    '  xxxxxxx ',
    '  xxxxxxx ',
    '   xxxxx  ',
    '   xxxx   ',
    '   oooo   ',
    '          ',
    '          ',
    '    @     '
  ].join("\n")
end

def test_fov_two_or_more_steps_away_from_wall_horizontal(_args, assert)
  map = FieldOfViewTest::Map.new([10, 10])
  map.block_sight [2, 2, 1, 3]
  field_of_view = FieldOfView.new(map)
  field_of_view.calculate(from: [0, 3])

  assert.equal! map.visibility_map(field_of_view), [
    '          ',
    '          ',
    '        xx',
    '      xxxx',
    '    xxxxxx',
    '  oxxxxxxx',
    '@ oxxxxxxx',
    '  oxxxxxxx',
    '    xxxxxx',
    '      xxxx'
  ].join("\n")
end

def test_fov_diagonal_left_of_horizontal_wall(_args, assert)
  map = FieldOfViewTest::Map.new([15, 7])
  map.block_sight [1, 2, 4, 1]
  field_of_view = FieldOfView.new(map)
  field_of_view.calculate(from: [0, 0])

  assert.equal! map.visibility_map(field_of_view), [
    '   xxxxxxxxxx  ',
    '   xxxxxxxx    ',
    '  xxxxxxx      ',
    '  xxxxx        ',
    ' oooo          ',
    '               ',
    '@              '
  ].join("\n")
end

def test_fov_diagonal_right_of_horizontal_wall(_args, assert)
  map = FieldOfViewTest::Map.new([15, 7])
  map.block_sight [10, 2, 4, 1]
  field_of_view = FieldOfView.new(map)
  field_of_view.calculate(from: [14, 0])

  assert.equal! map.visibility_map(field_of_view), [
    '  xxxxxxxxxx   ',
    '    xxxxxxxx   ',
    '      xxxxxxx  ',
    '        xxxxx  ',
    '          oooo ',
    '               ',
    '              @'
  ].join("\n")
end

def test_fov_diagonal_bottom_of_vertical_wall(_args, assert)
  map = FieldOfViewTest::Map.new([15, 9])
  map.block_sight [2, 1, 1, 4]
  field_of_view = FieldOfView.new(map)
  field_of_view.calculate(from: [0, 0])

  assert.equal! map.visibility_map(field_of_view), [
    '    xxxxxxxxxxx',
    '    xxxxxxxxxxx',
    '   xxxxxxxxxx  ',
    '   xxxxxxxx    ',
    '  oxxxxxx      ',
    '  oxxxx        ',
    '  oxx          ',
    '  o            ',
    '@              '
  ].join("\n")
end

def test_fov_diagonal_up_of_vertical_wall(_args, assert)
  map = FieldOfViewTest::Map.new([15, 9])
  map.block_sight [2, 4, 1, 4]
  field_of_view = FieldOfView.new(map)
  field_of_view.calculate(from: [0, 8])

  assert.equal! map.visibility_map(field_of_view), [
    '@              ',
    '  o            ',
    '  oxx          ',
    '  oxxxx        ',
    '  oxxxxxx      ',
    '   xxxxxxxx    ',
    '   xxxxxxxxxx  ',
    '    xxxxxxxxxxx',
    '    xxxxxxxxxxx'
  ].join("\n")
end

def test_fov_left_of_horizontal_wall(_args, assert)
  map = FieldOfViewTest::Map.new([7, 3])
  map.block_sight [2, 1, 3, 1]
  field_of_view = FieldOfView.new(map)
  field_of_view.calculate(from: [0, 1])

  assert.equal! map.visibility_map(field_of_view), [
    '       ',
    '@ oxxxx',
    '       '
  ].join("\n")
end

def test_fov_right_of_horizontal_wall(_args, assert)
  map = FieldOfViewTest::Map.new([7, 3])
  map.block_sight [2, 1, 3, 1]
  field_of_view = FieldOfView.new(map)
  field_of_view.calculate(from: [6, 1])

  assert.equal! map.visibility_map(field_of_view), [
    '       ',
    'xxxxo @',
    '       '
  ].join("\n")
end

def test_fov_down_of_vertical_wall(_args, assert)
  map = FieldOfViewTest::Map.new([3, 7])
  map.block_sight [1, 2, 1, 3]
  field_of_view = FieldOfView.new(map)
  field_of_view.calculate(from: [1, 0])

  assert.equal! map.visibility_map(field_of_view), [
    ' x ',
    ' x ',
    ' x ',
    ' x ',
    ' o ',
    '   ',
    ' @ '
  ].join("\n")
end

def test_fov_up_of_vertical_wall(_args, assert)
  map = FieldOfViewTest::Map.new([3, 7])
  map.block_sight [1, 2, 1, 3]
  field_of_view = FieldOfView.new(map)
  field_of_view.calculate(from: [1, 6])

  assert.equal! map.visibility_map(field_of_view), [
    ' @ ',
    '   ',
    ' o ',
    ' x ',
    ' x ',
    ' x ',
    ' x '
  ].join("\n")
end

def test_closest_point_on_wall_to(_args, assert)
  [
    { wall: [-4, 2, 2, 1], result: [-3, 2] },
    { wall: [4, 2, 2, 1], result: [4, 2] },
    { wall: [-4, 2, 8, 1], result: [0, 2] },
    { wall: [-2, -3, 1, 2], result: [-2, -2] },
    { wall: [-2, 3, 1, 2], result: [-2, 3] },
    { wall: [-2, -3, 1, 6], result: [-2, 0] }
  ].each do |test_data|
    assert.equal! FieldOfView.closest_point_on_wall_to(test_data[:wall], position: [0, 0]), test_data[:result]
  end
end

def test_sort_by_distance_to(_args, assert)
  #   aaa
  # bbbbbbb
  #    @
  obstacles = [
    [-1, 2, 3, 1], # a
    [-3, 1, 7, 1]  # b
  ]
  sorted = FieldOfView.sort_by_distance_to(obstacles, position: [0, 0])

  assert.equal! sorted, [
    [-3, 1, 7, 1], # b
    [-1, 2, 3, 1] # a
  ]
end

$gtk.reset 100
$gtk.log_level = :off
