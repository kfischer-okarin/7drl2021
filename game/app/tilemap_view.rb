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

  attr_reader :chunks

  def initialize(tilemap:, rect:, chunk_size:, tile_size:)
    @tilemap = tilemap
    @size = [rect.w, rect.h]
    @chunk_size = chunk_size
    @tile_size = tile_size
    self.origin = [rect.x, rect.y]
  end

  def origin=(value)
    @origin = value
    @chunk_rects = calc_chunk_rects(@origin + @size, @chunk_size)
    @chunks = @chunk_rects.map_with_index { |chunk_rect, index|
      TilemapChunk.new(
        tilemap: @tilemap,
        rect: chunk_rect,
        renderer: ChunkRenderer.new(target: :"chunk_#{index}", tile_size: @tile_size)
      )
    }
  end

  def calc_chunk_rects(rect, chunk_size)
    next_origin = bottom_left_chunk_origin(rect, chunk_size)
    left = next_origin.x
    [].tap { |result|
      loop do
        while next_origin.x < rect.right
          result << chunk_rect_at(next_origin, chunk_size)
          next_origin.x += chunk_size.x
        end
        next_origin.x = left
        next_origin.y += chunk_size.y
        break unless next_origin.y < rect.top
      end
    }
  end

  def bottom_left_chunk_origin(rect, chunk_size)
    [
      rect.x - (rect.x % chunk_size.x),
      rect.y - (rect.y % chunk_size.y)
    ]
  end

  def chunk_rect_at(origin, chunk_size)
    [origin.x, origin.y, chunk_size.x, chunk_size.y]
  end
end
