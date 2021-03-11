class StructureEditor
  def initialize(attributes = nil)
    values = attributes || {}
    @initialized = values[:initialized] || false
    @cell_size = values[:cell_size] || 48
    self.grid_size = [values[:w] || 2, values[:h] || 2]
    @structure = Structure.new(w: @w, h: @h)
    @grid_squares = build_grid_squares
    @palette_tiles = build_palette_tiles
    @selected_tile_index = 0
  end

  def grid_size=(value)
    @w, @h = value
    @grid_origin_x = (1280 - @w * @cell_size).idiv 2
    @grid_origin_y = (720 - @h * @cell_size).idiv 2
  end

  def tick(args)
    handle_click(args.inputs)
    draw_grid(args)
    draw_palette(args)
  end

  private

  def handle_click(gtk_inputs)
    return unless gtk_inputs.mouse.down

    handle_palette_selection(gtk_inputs.mouse)
    handle_draw(gtk_inputs.mouse)
  end

  def handle_palette_selection(mouse)
    clicked_palette_tile = @palette_tiles.find { |tile|
      mouse.inside_rect? tile
    }
    return unless clicked_palette_tile

    @selected_tile_index = clicked_palette_tile[:index]
  end

  def handle_draw(mouse)
    clicked_square = @grid_squares.find { |tile|
      mouse.inside_rect? tile
    }
    return unless clicked_square

    selected_tile = @palette_tiles[@selected_tile_index]
    @structure[clicked_square[:grid_x], clicked_square[:grid_y]] = mouse.button_right ? nil : selected_tile[:prototype]
  end

  PROTOTYPES = [
    { type: :tree, block_movement: true },
    { type: :wall, block_movement: true }
  ]

  def draw_palette(args)
    args.outputs.primitives << selected_tile_cursor
    args.outputs.primitives << @palette_tiles
  end

  def selected_tile_cursor
    selected = @palette_tiles[@selected_tile_index]
    [selected.x, selected.y, selected.w, selected.h, 255, 255, 255, 128].solid
  end

  def build_palette_tiles
    palette_width = 4
    PROTOTYPES.map_with_index { |prototype, index|
      Tile.for(prototype[:type]).tap { |tile|
        tile.w = @cell_size
        tile.h = @cell_size
        palette_x = index % palette_width
        palette_y = index.idiv palette_width
        tile.x = 1280 - palette_width * @cell_size + palette_x * @cell_size
        tile.y = 720 - (palette_y + 1) * @cell_size
        tile[:index] = index
        tile[:prototype] = prototype
      }
    }
  end

  def draw_grid(args)
    args.outputs.background_color = [0, 0, 0]
    args.outputs.primitives << @grid_squares
    @structure.each do |tile, x, y|
      next unless tile

      rendered_tile = Tile.for(tile[:type])
      rendered_tile.x = rendered_x(x)
      rendered_tile.y = rendered_y(y)
      rendered_tile.w = @cell_size
      rendered_tile.h = @cell_size
      args.outputs.primitives << rendered_tile
    end
  end

  def rendered_x(grid_x)
    @grid_origin_x + grid_x * @cell_size
  end

  def rendered_y(grid_y)
    @grid_origin_y + grid_y * @cell_size
  end

  def build_grid_squares
    @structure.each.map do |tile, x, y|
      {
        x: rendered_x(x),
        y: rendered_y(y),
        w: @cell_size,
        h: @cell_size,
        r: 255, g: 255, b: 255,
        grid_x: x,
        grid_y: y
      }.border
    end
  end
end
