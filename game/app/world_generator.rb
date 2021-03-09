class RNG
  def initialize
    @random = Random.new
  end

  # 0 .. max - 1
  def int(max)
    (@random.rand * max).floor
  end

  def int_between(min, max)
    int(max - min + 1) + min
  end

  def bool
    @random.rand >= 0.5
  end
end

class WorldGenerator
  def initialize
    @rng = RNG.new
  end

  def generate
    World.new.tap { |world|
      10.times do
        pos = [@rng.int(20), @rng.int(20)]
        wall_length = @rng.int_between(3, 6)
        size = @rng.bool ? [1, wall_length] : [wall_length, 1]
        (pos + size).each_position do |position|
          next if world.entities_at(position).any? { |entity| entity[:block_movement] }

          world.add_entity type: :tree, position: position, block_movement: true
        end
      end
    }
  end
end
