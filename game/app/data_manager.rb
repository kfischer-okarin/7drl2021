class DataManager
  class Accessor
    def initialize(manager, type)
      @manager = manager
      @type = type
    end

    def filename(id)
      "data/#{@type}/#{id}.txt"
    end

    def [](id)
      deserialized_hash = eval($gtk.read_file(filename(id)))
      deserialize_class = Kernel.const_get deserialized_hash[:deserialize_class]
      deserialize_class.deserialize deserialized_hash
    end

    def []=(id, value)
      $gtk.serialize_state(filename(id), value)
    end

    def add(value)
      index = @manager.index
      new_element_id = index[@type] || 0
      self[new_element_id] = value
      index[@type] = new_element_id + 1
      @manager.index = index
      new_element_id
    end
  end

  INDEX_FILE_NAME = 'data/index.txt'.freeze

  def index
    $gtk.deserialize_state(INDEX_FILE_NAME) || {}
  end

  def index=(value)
    $gtk.serialize_state(INDEX_FILE_NAME, value)
  end

  def structures
    @structures ||= Accessor.new(self, :structures)
  end
end
