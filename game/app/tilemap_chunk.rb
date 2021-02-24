class TilemapChunk
  def initialize(map_rect:, tilemap:, tile_renderer:, chunk_renderer:)
    self.map_rect = map_rect
    @tilemap = tilemap
    @tile_renderer = tile_renderer
    @chunk_renderer = chunk_renderer
    @full_redraw = true
  end

  def map_rect=(value)
    @map_rect = value
    @chunk_positions = calc_chunk_positions
    @full_redraw = true
  end

  def tick(args)
    return unless dirty?

    @chunk_positions.each do |chunk_position, map_position|
      tile = @tile_renderer.render_tile(@tilemap, map_position)
      @chunk_renderer.render_tile_at_position(args, tile, chunk_position)
    end
    @full_redraw = false
  end

  private

  def dirty?
    @full_redraw ||
      @tilemap.changed_positions.any? { |position| position.inside_rect? @map_rect }
  end

  def calc_chunk_positions
    [].tap { |result|
      (0...@map_rect.w).each do |x|
        (0...@map_rect.h).each do |y|
          result << [[x, y], [x + @map_rect.x, y + @map_rect.y]]
        end
      end
    }
  end
end
