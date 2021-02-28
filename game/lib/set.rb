class Set
  include Enumerable

  def initialize(*elements)
    @values = {}
    elements.each do |element|
      self << element
    end
  end

  def clear
    @values.clear
  end

  def size
    @values.size
  end

  def -(other)
    Set.new.tap { |result|
      each do |element|
        result << element unless other.include? element
      end
    }
  end

  def dup
    Set.new(*to_a)
  end

  def <<(element)
    @values[element] = true
    self
  end

  def delete(element)
    @values.delete element
    self
  end

  def include?(element)
    @values.key? element
  end

  def each(&block)
    @values.each_key(&block)
  end

  def ==(other)
    return false unless size == other.size

    all? { |value| other.include? value }
  end

  def inspect
    "Set.new(#{to_a.map(&:inspect).join(', ')})"
  end

  def to_s
    inspect
  end

  def serialize
    inspect
  end
end