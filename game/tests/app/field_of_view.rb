require 'tests/test_helper.rb'

module FieldOfViewTest
  class Map
    attr_reader :size

    def initialize(size)
      @size = size
      @blocking_sight = Set.new
    end

    def block_sight(position)
      @blocking_sight << position
    end

    def obstacles
      @blocking_sight.to_a
    end
  end

  def self.visible_positions(field_of_view)
    Set.new.tap { |result|
      field_of_view.each_position do |position|
        result << position if field_of_view.visible?(position.x, position.y)
      end
    }
  end
end

def test_fov_without_obstacle(_args, assert)
  map = FieldOfViewTest::Map.new([3, 3])
  field_of_view = FieldOfView.new(map)
  field_of_view.calculate(from: [0, 0])

  assert.equal! FieldOfViewTest.visible_positions(field_of_view), Set.new(
    [0, 2], [1, 2], [2, 2],
    [0, 1], [1, 1], [2, 1],
    [0, 0], [1, 0], [2, 0]
  )
end

def test_fov_behind_pillar(_args, assert)
  map = FieldOfViewTest::Map.new([3, 3])
  map.block_sight([1, 1])

  field_of_view = FieldOfView.new(map)
  field_of_view.calculate(from: [0, 1])

  assert.equal! FieldOfViewTest.visible_positions(field_of_view), Set.new(
    [0, 2], [1, 2], [2, 2],
    [0, 1], [1, 1],
    [0, 0], [1, 0], [2, 0]
  )

  field_of_view.calculate(from: [1, 0])

  assert.equal! FieldOfViewTest.visible_positions(field_of_view), Set.new(
    [0, 2],         [2, 2],
    [0, 1], [1, 1], [2, 1],
    [0, 0], [1, 0], [2, 0]
  )

  field_of_view.calculate(from: [2, 1])

  assert.equal! FieldOfViewTest.visible_positions(field_of_view), Set.new(
    [0, 2], [1, 2], [2, 2],
            [1, 1], [2, 1],
    [0, 0], [1, 0], [2, 0]
  )

  field_of_view.calculate(from: [1, 2])

  assert.equal! FieldOfViewTest.visible_positions(field_of_view), Set.new(
    [0, 2], [1, 2], [2, 2],
    [0, 1], [1, 1], [2, 1],
    [0, 0],         [2, 0]
  )
end

$gtk.reset 100
$gtk.log_level = :off
