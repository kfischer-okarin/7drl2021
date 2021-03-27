class World
  def self.build_empty_state(args)
    args.state.new_entity_strict(
      :world,
      entities: {},
      entities_by_component: {},
      entities_by_position: {},
      messages: [],
      changed_positions: [],
      next_entity_id: 0
    )
  end

  class EntitySet
    def self.build_empty_state
      { all: [], by_position: {} }
    end

    def initialize(world, entities)
      @world = world
      @entities = entities
    end

    def each(&block)
      to_a.each(&block)
    end

    def inside_rect(rect)
      entities_by_position = @entities[:by_position]
      Enumerator.new do |y|
        rect.each_position do |position|
          next unless entities_by_position.key? position

          entities_by_position[position].each do |entity_id|
            y << @world.entity(entity_id)
          end
        end
      end
    end

    def <<(entity)
      @entities[:all] << entity[:id]
      index_by_position entity
    end

    def size
      @entities[:all].size
    end

    def include?(entity)
      @entities[:all].include? entity[:id]
    end

    def to_a
      @entities[:all].map { |entity_id| @world.entity(entity_id) }
    end

    private

    def index_by_position(entity)
      @entities[:by_position][entity[:position]] ||= []
      @entities[:by_position][entity[:position]] << entity[:id]

    end
  end

  def initialize(state)
    @state = state
  end

  def messages
    @state.messages
  end

  def changed_positions
    @state.changed_positions
  end

  def tick
    handle_movement
  end

  def add_entity(components)
    next_entity_id.tap { |id|
      entity = { id: id }.merge(components)
      @state.entities[id] = entity
      index_by_components entity
      index_by_position entity
    }
  end

  def entities_with(component)
    @state.entities_by_component[component] ||= EntitySet.build_empty_state
    EntitySet.new(self, @state.entities_by_component[component])
  end

  def entities_at(position)
    (@state.entities_by_position[position] || []).map do |entity_id|
      @state.entities[entity_id]
    end
  end

  def set_entity_property(id, attributes)
    @state.entities[id].update(attributes)
  end

  def get_entity_property(id, attribute)
    @state.entities[id][attribute]
  end

  def has?(entity_components, at:)
    entities_at(at).any? { |entity| entity_components.all? { |component, value| entity[component] == value} }
  end

  def entity(id)
    @state.entities[id]
  end

  private

  def next_entity_id
    result = @state.next_entity_id
    @state.next_entity_id += 1
    result
  end

  def index_by_components(entity)
    entity.each do |component, _|
      next if component == :id

      entities_with(component) << entity
    end
  end

  def index_by_position(entity)
    @state.entities_by_position[entity[:position]] ||= []
    @state.entities_by_position[entity[:position]] << entity[:id]
  end

  def collided_entity(entity)
    new_position = entity[:position].vector_add entity[:velocity]
    entities_at(new_position).find { |other_entity| other_entity[:block_movement] }
  end

  def handle_collision(entity)
    collided_entity = collided_entity(entity)
    return unless collided_entity

    entity[:velocity] = [0, 0]

    @state.messages.unshift "You run into a #{collided_entity[:type]}" if entity[:type] == :player
  end

  def set_new_position(entity, new_position)
    @state.changed_positions << entity[:position].dup
    @state.entities_by_position[entity[:position]]&.delete(entity[:id])

    entity[:position] = new_position
    @state.changed_positions << new_position.dup
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
