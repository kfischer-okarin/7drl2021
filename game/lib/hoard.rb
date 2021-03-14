class Hoard
  INDEX_KEY = '.index'.freeze

  def initialize(directory)
    @directory = directory
    @index = self[INDEX_KEY] || { files: [] }
  end

  def [](key)
    $gtk.deserialize_state filename(key)
  rescue SyntaxError
    # Non-existing or invalid file
  end

  def []=(key, object)
    serialize_object(key, object)
    @index[:files] << key
    serialize_object(INDEX_KEY, @index)
  end

  def size
    @index[:files].size
  end

  private

  def filename(key)
    "#{@directory}/#{key}"
  end

  def serialize_object(key, object)
    $gtk.serialize_state(filename(key), object)
  end
end
