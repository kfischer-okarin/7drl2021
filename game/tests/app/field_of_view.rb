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
            if @blocking_sight.any? { |obstacle| obstacle == [x, y] || [x, y].inside_grid_rect?(obstacle) }
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

def test_fov_with_longer_wall(_args, assert)
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

$gtk.reset 100
$gtk.log_level = :off
