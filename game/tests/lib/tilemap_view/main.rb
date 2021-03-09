def test_tilemap_view_renders_correct_chunks(_args, assert)
  view = TilemapView.new(name: :view, tilemap: :tilemap, rect: [3, 4, 40, 30], chunk_size: [16, 16], tile_size: 1)

  chunk_rects = Set.new(view.chunks.map(&:rect))

  assert.equal! chunk_rects, Set.new([
    [0, 0, 16, 16],
    [16, 0, 16, 16],
    [32, 0, 16, 16],
    [0, 16, 16, 16],
    [16, 16, 16, 16],
    [32, 16, 16, 16],
    [0, 32, 16, 16],
    [16, 32, 16, 16],
    [32, 32, 16, 16]
  ])
end

def test_tilemap_view_renders_chunks_at_correct_positions(_args, assert)
  view = TilemapView.new(name: :view, tilemap: :tilemap, rect: [7, 9, 20, 10], chunk_size: [16, 16], tile_size: 4)

  rects_and_positions = Set.new(view.chunks.map { |chunk| [chunk.rect, [chunk.x, chunk.y]] })

  assert.equal! rects_and_positions, Set.new([
    [[0, 0, 16, 16], [-7 * 4, -9 * 4]],
    [[16, 0, 16, 16], [9 * 4, -9 * 4]],
    [[0, 16, 16, 16], [-7 * 4, 7 * 4]],
    [[16, 16, 16, 16], [9 * 4, 7 * 4]]
  ])
end

def test_tilemap_view_updates_chunks_origin_changes(_args, assert)
  view = TilemapView.new(name: :view, tilemap: :tilemap, rect: [3, 4, 40, 30], chunk_size: [16, 16], tile_size: 1)

  view.origin = [19, 4]

  chunk_rects = Set.new(view.chunks.map(&:rect))

  assert.equal! chunk_rects, Set.new([
    [16, 0, 16, 16],
    [32, 0, 16, 16],
    [48, 0, 16, 16],
    [16, 16, 16, 16],
    [32, 16, 16, 16],
    [48, 16, 16, 16],
    [16, 32, 16, 16],
    [32, 32, 16, 16],
    [48, 32, 16, 16]
  ])
end

$gtk.reset 100
$gtk.log_level = :off
