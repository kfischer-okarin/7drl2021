class World
  attr_reader :changed_positions, :messages

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
    @messages = []
  end

  def entities_with(component)
    @entities_by_component[component]
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

  def tick
    handle_movement
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

  def collided_entity(entity)
    new_position = entity[:position].vector_add entity[:velocity]
    entities_at(new_position).find { |other_entity| other_entity[:block_movement] }
  end

  def handle_collision(entity)
    collided_entity = collided_entity(entity)
    return unless collided_entity

    entity[:velocity] = [0, 0]

    @messages.unshift "You run into a #{collided_entity[:type]}" if entity[:type] == :player
  end

  def set_new_position(entity, new_position)
    @changed_positions << entity[:position].dup
    @entities_by_position[entity[:position]]&.delete(entity)

    entity[:position] = new_position
    @changed_positions << new_position.dup
    index_by_position entity
  end

  def handle_movement
    entities_with(:velocity).each do |entity|
      handle_collision(entity)
      velocity = entity[:velocity]
      next if velocity.zero?

      set_new_position(entity, entity[:position].vector_add(velocity))
    end
  end
end
