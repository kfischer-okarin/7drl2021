class World
  def initialize
    @entities = {}
    @entities_by_component = {}
    @next_entity_id = 0
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
      components.keys.each do |component|
        @entities_by_component[component] ||= []
        @entities_by_component[component] << entity
      end
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
    handle_movement
  end

  def entities_inside_rect(rect)
    entities.select { |entity|
      position_of(entity).inside_rect? rect
    }
  end

  private

  def next_entity_id
    result = @next_entity_id
    @next_entity_id += 1
    result
  end

  def handle_movement
    @entities_by_component[:velocity].each do |entity|
      position = entity[:position]
      velocity = entity[:velocity]
      position.x += velocity.x
      position.y += velocity.y
    end
  end
end
