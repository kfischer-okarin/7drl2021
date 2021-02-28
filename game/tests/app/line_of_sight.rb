require 'tests/test_helper.rb'

module LineOfSightTest
  class Map
    def initialize
      @blocking_sight = Set.new
    end

    def block_sight(position)
      @blocking_sight << position
    end

    def blocking_positions_in(rect)
      @blocking_sight.select { |position| position.inside_rect? rect }
    end
  end
end

def test_line_of_sight_without_obstacle(_args, assert)
  map = LineOfSightTest::Map.new
  line_of_sight = LineOfSight.new(map, from: [0, 0], area: [0, 0, 3, 3])

  assert.equal! line_of_sight.visible_positions, Set.new(
    [0, 2], [1, 2], [2, 2],
    [0, 1], [1, 1], [2, 1],
    [0, 0], [1, 0], [2, 0]
  )
end

# Line intersection tests

def test_horizontal_line_parallel_to_horizontal_line(_args, assert)
  line1 = LineOfSight::HorizontalLine.new(0, 1, y: 0)
  line2 = LineOfSight::HorizontalLine.new(0, 1, y: 1)

  assert.nil! line1.intersection_with(line2)
end

def test_horizontal_line_identical_to_horizontal_line(_args, assert)
  line1 = LineOfSight::HorizontalLine.new(0, 1, y: 0)
  line2 = LineOfSight::HorizontalLine.new(0, 1, y: 0)

  assert.equal! line1.intersection_with(line2), :identical
end

def test_vertical_line_parallel_to_vertical_line(_args, assert)
  line1 = LineOfSight::VerticalLine.new(0, 1, x: 0)
  line2 = LineOfSight::VerticalLine.new(0, 1, x: 1)

  assert.nil! line1.intersection_with(line2)
end

def test_vertical_line_identical_to_vertical_line(_args, assert)
  line1 = LineOfSight::VerticalLine.new(0, 1, x: 0)
  line2 = LineOfSight::VerticalLine.new(0, 1, x: 0)

  assert.equal! line1.intersection_with(line2), :identical
end

def test_horizontal_line_intersect_vertical_line(_args, assert)
  line1 = LineOfSight::HorizontalLine.new(0, 1, y: 10)
  line2 = LineOfSight::VerticalLine.new(0, 2, x: 5)

  assert.equal! line1.intersection_with(line2), 5
end

def test_vertical_line_intersect_horizontal_line(_args, assert)
  line1 = LineOfSight::VerticalLine.new(0, 1, x: -3)
  line2 = LineOfSight::HorizontalLine.new(0, 2, y: 5)

  assert.equal! line1.intersection_with(line2), -1.5
end

def test_line_intersect_horizontal_line(_args, assert)
  line1 = LineOfSight::Line.new([1, 1], [2, 3])
  line2 = LineOfSight::HorizontalLine.new(0, 2, y: 5)

  assert.equal! line1.intersection_with(line2), 1.5
end

def test_line_intersect_vertical_line(_args, assert)
  line1 = LineOfSight::Line.new([1, 1], [2, 3])
  line2 = LineOfSight::VerticalLine.new(0, 2, x: 5)

  assert.equal! line1.intersection_with(line2), 4.5
end

$gtk.reset 100
$gtk.log_level = :off
