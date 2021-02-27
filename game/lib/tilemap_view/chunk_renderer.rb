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
