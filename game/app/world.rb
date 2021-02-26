require 'app/set.rb'

class World
  attr_reader :changed_positions

  def initialize(entities: nil, next_entity_id: 0)
    @entities = entities || {}
    @entities_by_position = {}
    @entities_by_component = {}
    self.entities.each do |entity|
      index_by_components entity
      index_by_position entity
    end
    @next_entity_id = next_entity_id
    @changed_positions = Set.new
  end

  def entities
    @entities.values
  end

  def entity(id)
    @entities[id]
  end

  def add_entity(type, components)
    next_entity_id.tap { |id|
      entity = { type: type, id: id }.merge(components)
      @entities[id] = entity
      index_by_components entity
      index_by_position entity
    }
  end

  def set_entity_property(id, attributes)
    @entities[id].merge!(attributes)
  end

  def get_entity_property(id, property)
    @entities[id][property]
  end

  def position_of(entity)
    entity[:position]
  end

  def tick
    handle_collision
    handle_movement
  end

  def entities_inside_rect(rect)
    entities.select { |entity|
      position_of(entity).inside_rect? rect
    }
  end

  def entities_at(position)
    @entities_by_position[position] || []
  end

  def serialize
    "World.new(entities: #{@entities.inspect}, next_entity_id: #{@next_entity_id})"
  end

  def inspect
    serialize
  end

  def to_s
    serialize
  end

  private

  def next_entity_id
    result = @next_entity_id
    @next_entity_id += 1
    result
  end

  def index_by_components(entity)
    entity.each do |component, _|
      next if component == :id || component == :type

      @entities_by_component[component] ||= []
      @entities_by_component[component] << entity
    end
  end

  def index_by_position(entity)
    @entities_by_position[entity[:position]] ||= []
    @entities_by_position[entity[:position]] << entity
  end

  def remove_from_position_index(entity)
    return unless @entities_by_position[entity[:position]]

    @entities_by_position[entity[:position]].delete(entity)
  end

  def moving_entities
    Enumerator.new do |yielder|
      @entities_by_component[:velocity].each do |entity|
        velocity = entity[:velocity]
        position = entity[:position]
        new_position = [position.x + velocity.x, position.y + velocity.y]
        yielder.yield(entity, velocity, new_position) unless velocity.x.zero? && velocity.y.zero?
      end
    end
  end

  def handle_collision
    moving_entities.each do |entity, velocity, new_position|
      blocking_entity = entities_at(new_position).find { |other_entity| other_entity[:block_movement] }
      next unless blocking_entity

      velocity.x = 0
      velocity.y = 0
    end
  end

  def handle_movement
    moving_entities.each do |entity, _velocity, new_position|
      position = entity[:position]
      @changed_positions << position.dup
      remove_from_position_index entity
      position.x = new_position.x
      position.y = new_position.y
      @changed_positions << position.dup
      index_by_position entity
    end
  end
end
