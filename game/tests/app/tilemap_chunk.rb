module TilemapChunkTest
  def self.chunk_with(tilemap: nil, chunk_renderer: nil, map_rect:)
    TilemapChunk.new(
      map_rect: map_rect,
      tilemap: tilemap || Tilemap.new,
      chunk_renderer: chunk_renderer || ChunkRenderer.new
    )
  end

  class Tilemap
    attr_accessor :changed_positions

    def initialize
      @changed_positions = Set.new
    end

    def tile_at(position)
      { position: position }
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
  chunk_renderer = TilemapChunkTest::ChunkRenderer.new

  chunk = TilemapChunkTest.chunk_with(map_rect: [4, 4, 2, 2], chunk_renderer: chunk_renderer)
  chunk.tick(args)

  assert.equal! chunk_renderer.rendered, Set.new(
    [{ position: [4, 4] }, [0, 0]],
    [{ position: [4, 5] }, [0, 1]],
    [{ position: [5, 4] }, [1, 0]],
    [{ position: [5, 5] }, [1, 1]],
  )
end

def test_update_renders_all_tiles_when_tile_in_area_changes(args, assert)
  tilemap = TilemapChunkTest::Tilemap.new
  chunk_renderer = TilemapChunkTest::ChunkRenderer.new

  chunk = TilemapChunkTest.chunk_with(map_rect: [0, 0, 2, 2], tilemap: tilemap, chunk_renderer: chunk_renderer)
  chunk.tick(args)
  chunk_renderer.clear

  tilemap.changed_positions = Set.new([1, 1])
  chunk.tick(args)
  assert.equal! chunk_renderer.rendered, Set.new(
    [{ position: [0, 0] }, [0, 0]],
    [{ position: [0, 1] }, [0, 1]],
    [{ position: [1, 0] }, [1, 0]],
    [{ position: [1, 1] }, [1, 1]],
  )
end

def test_update_renders_nothing_when_tile_outside_area_changes(args, assert)
  tilemap = TilemapChunkTest::Tilemap.new
  chunk_renderer = TilemapChunkTest::ChunkRenderer.new

  chunk = TilemapChunkTest.chunk_with(map_rect: [0, 0, 2, 2], tilemap: tilemap, chunk_renderer: chunk_renderer)
  chunk.tick(args)
  chunk_renderer.clear

  tilemap.changed_positions = Set.new([5, 5])
  chunk.tick(args)
  assert.equal! chunk_renderer.rendered, Set.new
end

def test_update_renders_all_tiles_when_map_rect_changes(args, assert)
  tilemap = TilemapChunkTest::Tilemap.new
  chunk_renderer = TilemapChunkTest::ChunkRenderer.new

  chunk = TilemapChunkTest.chunk_with(map_rect: [0, 0, 2, 2], tilemap: tilemap, chunk_renderer: chunk_renderer)
  chunk.tick(args)
  chunk_renderer.clear

  chunk.map_rect = [2, 3, 2, 2]
  chunk.tick(args)
  assert.equal! chunk_renderer.rendered, Set.new(
    [{ position: [2, 3] }, [0, 0]],
    [{ position: [2, 4] }, [0, 1]],
    [{ position: [3, 3] }, [1, 0]],
    [{ position: [3, 4] }, [1, 1]],
  )
end

$gtk.reset 100
$gtk.log_level = :off
