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

  def initialize(tilemap:, rect:, chunk_size:, tile_size:)
    @tilemap = tilemap
    @size = [rect.w, rect.h]
    @rect_calculator = RectCalculator.new(chunk_size)
    @tile_size = tile_size
    @chunks_by_rect = {}
    @chunk_rects = Set.new
    @next_chunk_index = 0
    self.origin = [rect.x, rect.y]
  end

  def origin=(value)
    return unless @origin != value

    @origin = value
    new_rects = []
    deleted_rects = @chunk_rects.dup
    @rect_calculator.chunk_rects_for(@origin + @size).each do |rect|
      if @chunk_rects.include? rect
        deleted_rects.delete rect
      else
        new_rects << rect
      end
    end
    new_rects.each do |rect|
      @chunk_rects << rect
    end
    deleted_rects.each do |rect|
      @chunk_rects.delete rect
    end
    deleted_rects = deleted_rects.to_a

    new_rects.each do |rect|
      chunk = if deleted_rects.empty?
                TilemapChunk.new(
                  tilemap: @tilemap,
                  rect: rect,
                  renderer: ChunkRenderer.new(target: :"chunk_#{@next_chunk_index}", tile_size: @tile_size)
                ).tap {
                  @next_chunk_index += 1
                }
              else
                @chunks_by_rect.delete(deleted_rects.pop).tap { |reused_chunk|
                  reused_chunk.rect = rect
                }
              end
      @chunks_by_rect[rect] = chunk
    end

    chunks.each do |chunk|
      chunk.x = (chunk.rect.x - @origin.x) * @tile_size
      chunk.y = (chunk.rect.y - @origin.y) * @tile_size
    end
  end

  def chunks
    @chunks_by_rect.each_value
  end

  def tick(args)
    chunks.each do |chunk|
      chunk.tick(args)
    end
  end

  def primitive_marker
    :sprite
  end

  def draw_override(ffi_draw)
    chunks.each do |chunk|
      chunk.draw_override(ffi_draw)
    end
  end
end
