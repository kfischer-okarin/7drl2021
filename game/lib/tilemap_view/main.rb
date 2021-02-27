class TilemapView
  class ChunkRenderer
    attr_reader :path, :tile_size

    def initialize(target:, tile_size:)
      @path = target
      @tile_size = tile_size
    end

    def render_size(chunk)
      [chunk.rect.w * @tile_size, chunk.rect.h * @tile_size]
    end

    def init_render(args, chunk)
      target = args.outputs[@path]
      target.width, target.height = render_size(chunk)
    end

    def render_tile_at(args, tile, position)
      target = args.outputs[@path]
      tile.x = position.x * @tile_size
      tile.y = position.y * @tile_size
      target.primitives << tile
    end
  end

  class RectCalculator
    def initialize(chunk_size)
      @chunk_size = chunk_size
    end

    def chunk_rects_for(rect)
      next_origin = bottom_left_chunk_origin(rect)
      left = next_origin.x
      Set.new.tap { |result|
        loop do
          while next_origin.x < rect.right
            result << build_rect(next_origin)
            next_origin.x += @chunk_size.x
          end
          next_origin.x = left
          next_origin.y += @chunk_size.y
          break unless next_origin.y < rect.top
        end
      }
    end

    private

    def bottom_left_chunk_origin(rect)
      [
        rect.x - (rect.x % @chunk_size.x),
        rect.y - (rect.y % @chunk_size.y)
      ]
    end

    def build_rect(origin)
      [origin.x, origin.y, @chunk_size.x, @chunk_size.y]
    end
  end

  def self.difference(set1, set2)
    new_elements = []
    deleted_elements = set1.dup
    set2.each do |element|
      if set1.include? element
        deleted_elements.delete element
      else
        new_elements << element
      end
    end

    [new_elements, deleted_elements.to_a]
  end

  attr_accessor :x, :y
  attr_reader :origin

  def initialize(name:, tilemap:, rect:, chunk_size:, tile_size:)
    @name = name
    @tilemap = tilemap
    @size = [rect.w, rect.h]
    @tile_size = tile_size
    @w = rect.w * @tile_size
    @h = rect.h * @tile_size
    @rect_calculator = RectCalculator.new(chunk_size)
    @chunks_by_rect = {}
    @chunk_rects = Set.new
    @unused_chunks = []
    @next_chunk_index = 0
    @full_redraw = false
    self.origin = [rect.x, rect.y]
  end

  def path
    @name
  end

  def origin=(value)
    return unless @origin != value

    @origin = value
    new_rects, deleted_rects = TilemapView.difference @chunk_rects, @rect_calculator.chunk_rects_for(@origin + @size)
    update_rects(new_rects, deleted_rects)

    new_rects.each do |rect|
      add_new_chunk(rect)
    end

    update_chunk_positions
    @full_redraw = true
  end

  def chunks
    @chunks_by_rect.each_value
  end

  def tick(args)
    chunks.each do |chunk|
      chunk.tick(args)
    end
    return unless @full_redraw

    target = args.outputs[@name]
    target.width = @w
    target.height = @h
    target.primitives << chunks
    @full_redraw = false
  end

  def primitive_marker
    :sprite
  end

  def draw_override(ffi_draw)
    ffi_draw.draw_sprite @x, @y, @w, @h, path.to_s
  end

  private

  def update_rects(new_rects, deleted_rects)
    new_rects.each do |rect|
      @chunk_rects << rect
    end
    deleted_rects.each do |rect|
      @chunk_rects.delete rect
      @unused_chunks << @chunks_by_rect.delete(rect)
    end
  end

  def add_new_chunk(rect)
    chunk = @unused_chunks.empty? ? build_new_chunk(rect) : reuse_unused_chunk(rect)
    @chunks_by_rect[rect] = chunk
  end

  def build_new_chunk(rect)
    Chunk.new(
      tilemap: @tilemap,
      rect: rect,
      renderer: ChunkRenderer.new(target: :"#{@name}_#{@next_chunk_index}", tile_size: @tile_size)
    ).tap {
      @next_chunk_index += 1
    }
  end

  def reuse_unused_chunk(rect)
    @unused_chunks.pop.tap { |chunk|
      chunk.rect = rect
    }
  end

  def update_chunk_positions
    chunks.each do |chunk|
      chunk.x = (chunk.rect.x - @origin.x) * @tile_size
      chunk.y = (chunk.rect.y - @origin.y) * @tile_size
    end
  end
end
