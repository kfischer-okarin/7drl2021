def test_tilemap_view_consists_of_the_right_chunks(_args, assert)
  view = TilemapView.new(tilemap: :tilemap, rect: [3, 4, 40, 30], chunk_size: [16, 16], tile_size: 1)

  chunk_rects = Set.new(*view.chunks.map(&:rect))

  assert.equal! chunk_rects, Set.new(
    [0, 0, 16, 16],
    [16, 0, 16, 16],
    [32, 0, 16, 16],
    [0, 16, 16, 16],
    [16, 16, 16, 16],
    [32, 16, 16, 16],
    [0, 32, 16, 16],
    [16, 32, 16, 16],
    [32, 32, 16, 16]
  )
end

def test_chunks_update_when_view_origin_changes(_args, assert)
  view = TilemapView.new(tilemap: :tilemap, rect: [3, 4, 40, 30], chunk_size: [16, 16], tile_size: 1)

  view.origin = [19, 4]

  chunk_rects = Set.new(*view.chunks.map(&:rect))

  assert.equal! chunk_rects, Set.new(
    [16, 0, 16, 16],
    [32, 0, 16, 16],
    [48, 0, 16, 16],
    [16, 16, 16, 16],
    [32, 16, 16, 16],
    [48, 16, 16, 16],
    [16, 32, 16, 16],
    [32, 32, 16, 16],
    [48, 32, 16, 16]
  )
end

$gtk.reset 100
$gtk.log_level = :off
