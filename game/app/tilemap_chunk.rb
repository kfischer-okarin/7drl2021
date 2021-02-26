class TilemapChunk
  attr_accessor :x, :y
  attr_reader :rect

  def initialize(tilemap:, rect:, renderer:)
    @tilemap = tilemap
    @renderer = renderer
    self.rect = rect
  end

  def path
    @renderer.path
  end

  def rect=(value)
    @rect = value
    @chunk_positions = calc_chunk_positions
    @w, @h = @renderer.render_size(self)
    @full_redraw = true
  end

  def tick(args)
    return unless dirty?

    @renderer.init_render(args, self)
    @chunk_positions.each do |chunk_position, map_position|
      tile = @tilemap.tile_at(map_position)
      @renderer.render_tile_at_position(args, tile, chunk_position)
    end
    @full_redraw = false
  end

  def primitive_marker
    :sprite
  end

  def draw_override(ffi_draw)
    ffi_draw.draw_sprite @x, @y, @w, @h, path.to_s
  end

  private

  def dirty?
    @full_redraw ||
      @tilemap.changed_positions.any? { |position| position.inside_rect? @rect }
  end

  def calc_chunk_positions
    [].tap { |result|
      (0...@rect.w).each do |x|
        (0...@rect.h).each do |y|
          result << [[x, y], [x + @rect.x, y + @rect.y]]
        end
      end
    }
  end
end
