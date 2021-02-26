module TilemapChunkTest
  def self.chunk_with(tilemap: nil, tile_renderer: nil, chunk_renderer: nil, map_rect:)
    TilemapChunk.new(
      map_rect: map_rect,
      tilemap: tilemap || Tilemap.new,
      tile_renderer: tile_renderer || TileRenderer.new,
      chunk_renderer: chunk_renderer || ChunkRenderer.new
    )
  end

  class Tilemap
    attr_accessor :changed_positions

    def initialize
      @changed_positions = Set.new
    end
  end

  class TileRenderer
    attr_reader :rendered

    def initialize
      @rendered = Set.new
    end

    def render_tile(_world, position)
      @rendered << position
      { position: position }
    end

    def clear
      @rendered.clear
    end
  end

  class ChunkRenderer
    attr_reader :rendered

    def initialize
      @rendered = Set.new
    end

    def init_render(_args, _chunk); end

    def render_size(_chunk)
      [1, 1]
    end

    def render_tile_at_position(_args, tile, position)
      @rendered << [tile, position]
    end

    def clear
      @rendered.clear
    end
  end
end

def test_update_renders_all_tiles_after_creation(args, assert)
  tile_renderer = TilemapChunkTest::TileRenderer.new
  chunk_renderer = TilemapChunkTest::ChunkRenderer.new

  chunk = TilemapChunkTest.chunk_with(map_rect: [4, 4, 2, 2], tile_renderer: tile_renderer, chunk_renderer: chunk_renderer)
  chunk.tick(args)

  assert.equal! tile_renderer.rendered, Set.new([4, 4], [4, 5], [5, 4], [5, 5])
  assert.equal! chunk_renderer.rendered, Set.new(
    [{ position: [4, 4] }, [0, 0]],
    [{ position: [4, 5] }, [0, 1]],
    [{ position: [5, 4] }, [1, 0]],
    [{ position: [5, 5] }, [1, 1]],
  )
end

def test_update_renders_all_tiles_when_tile_in_area_changes(args, assert)
  tilemap = TilemapChunkTest::Tilemap.new
  tile_renderer = TilemapChunkTest::TileRenderer.new

  chunk = TilemapChunkTest.chunk_with(map_rect: [0, 0, 2, 2], tilemap: tilemap, tile_renderer: tile_renderer)
  chunk.tick(args)
  tile_renderer.clear

  tilemap.changed_positions = Set.new([1, 1])
  chunk.tick(args)
  assert.equal! tile_renderer.rendered, Set.new([0, 0], [0, 1], [1, 0], [1, 1])
end

def test_update_renders_nothing_when_tile_outside_area_changes(args, assert)
  tilemap = TilemapChunkTest::Tilemap.new
  tile_renderer = TilemapChunkTest::TileRenderer.new

  chunk = TilemapChunkTest.chunk_with(map_rect: [0, 0, 2, 2], tilemap: tilemap, tile_renderer: tile_renderer)
  chunk.tick(args)
  tile_renderer.clear

  tilemap.changed_positions = Set.new([5, 5])
  chunk.tick(args)
  assert.equal! tile_renderer.rendered, Set.new
end

def test_update_renders_all_tiles_when_map_rect_changes(args, assert)
  tilemap = TilemapChunkTest::Tilemap.new
  tile_renderer = TilemapChunkTest::TileRenderer.new

  chunk = TilemapChunkTest.chunk_with(map_rect: [0, 0, 2, 2], tilemap: tilemap, tile_renderer: tile_renderer)
  chunk.tick(args)
  tile_renderer.clear

  chunk.map_rect = [2, 3, 2, 2]
  chunk.tick(args)
  assert.equal! tile_renderer.rendered, Set.new([2, 3], [2, 4], [3, 3], [3, 4])
end

$gtk.reset 100
$gtk.log_level = :off
