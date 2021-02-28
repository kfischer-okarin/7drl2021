require 'tests/test_helper.rb'

module FieldOfViewTest
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

def test_fov_without_obstacle(_args, assert)
  map = FieldOfViewTest::Map.new
  line_of_sight = FieldOfView.new(map, from: [0, 0], area: [0, 0, 3, 3])

  assert.equal! line_of_sight.visible_positions, Set.new(
    [0, 2], [1, 2], [2, 2],
    [0, 1], [1, 1], [2, 1],
    [0, 0], [1, 0], [2, 0]
  )
end

def test_fov_behind_pillar(_args, assert)
  map = FieldOfViewTest::Map.new
  map.block_sight([1, 1])

  line_of_sight = FieldOfView.new(map, from: [0, 1], area: [0, 0, 3, 3])

  assert.equal! line_of_sight.visible_positions, Set.new(
    [0, 2], [1, 2], [2, 2],
    [0, 1], [1, 1],
    [0, 0], [1, 0], [2, 0]
  )

  line_of_sight = FieldOfView.new(map, from: [1, 0], area: [0, 0, 3, 3])

  assert.equal! line_of_sight.visible_positions, Set.new(
    [0, 2],         [2, 2],
    [0, 1], [1, 1], [2, 1],
    [0, 0], [1, 0], [2, 0]
  )

  line_of_sight = FieldOfView.new(map, from: [2, 1], area: [0, 0, 3, 3])

  assert.equal! line_of_sight.visible_positions, Set.new(
    [0, 2], [1, 2], [2, 2],
            [1, 1], [2, 1],
    [0, 0], [1, 0], [2, 0]
  )

  line_of_sight = FieldOfView.new(map, from: [1, 2], area: [0, 0, 3, 3])

  assert.equal! line_of_sight.visible_positions, Set.new(
    [0, 2], [1, 2], [2, 2],
    [0, 1], [1, 1], [2, 1],
    [0, 0],         [2, 0]
  )
end

$gtk.reset 100
$gtk.log_level = :off
