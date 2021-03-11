class StructureEditor
  def initialize(attributes = nil)
    values = attributes || {}
    @initialized = values[:initialized] || false
    @cell_size = values[:cell_size] || 48
    @w = values[:w] || 2
    @h = values[:h] || 2
    after_size_update
    @palette_tiles = build_palette_tiles
    @selected_tile_index = 0
    @static_toolbar = [
      toolbar_icon('-', 1).merge(method: :dec_w),
      toolbar_icon('W', 2),
      toolbar_icon('+', 3).merge(method: :inc_w),
      toolbar_icon('-', 5).merge(method: :dec_h),
      toolbar_icon('H', 6),
      toolbar_icon('+', 7).merge(method: :inc_h),
      toolbar_icon('N', 9).merge(method: :new_structure),
      toolbar_icon('S', 10).merge(method: :save),
    ]
    @data_manager = DataManager.new
    @structure_count = @data_manager.index[:structures] || 0
    @structure_id = -1
  end

  def update_grid
    @grid_origin_x = (1280 - @w * @cell_size).idiv 2
    @grid_origin_y = (720 - @h * @cell_size).idiv 2
    @grid_squares = build_grid_squares
  end

  def after_size_update
    if @structure
      old_structure = @structure
      @structure = Structure.new(w: @w, h: @h)
      @structure.insert(old_structure, at: [0, 0])
    else
      @structure = Structure.new(w: @w, h: @h)
    end

    update_grid
  end

  def after_structure_update
    @w = @structure.w
    @h = @structure.w

    update_grid
  end

  def tick(args)
    handle_click(args.inputs)
    draw_grid(args)
    draw_palette(args)
    draw_toolbar(args)
  end

  private

  def toolbar
    @static_toolbar.dup.tap { |result|
      if @structure_count.positive?
        result.concat [
          toolbar_icon(:arrow_left, 12).merge(method: :load_previous),
          toolbar_icon(:arrow_right, 14).merge(method: :load_next)
        ]
      end
    }
  end

  def handle_click(gtk_inputs)
    return unless gtk_inputs.mouse.down

    handle_palette_selection(gtk_inputs.mouse)
    handle_draw(gtk_inputs.mouse)
    handle_toolbar(gtk_inputs.mouse)
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

  def handle_toolbar(mouse)
    clicked_button = toolbar.find { |button|
      mouse.inside_rect? button
    }
    return unless clicked_button && clicked_button[:method]

    send(clicked_button[:method])
  end

  def inc_w
    @w = [@w + 1, 10].min
    after_size_update
  end

  def dec_w
    @w = [@w - 1, 1].max
    after_size_update
  end

  def inc_h
    @h = [@h + 1, 10].min
    after_size_update
  end

  def dec_h
    @h = [@h - 1, 1].max
    after_size_update
  end

  def save
    if @structure_id == -1
      @structure_id = @data_manager.structures.add @structure
      @structure_count += 1
    else
      @data_manager.structures[@structure_id] = @structure
    end
  end

  def load_structure(id)
    @structure_id = id
    @structure = @data_manager.structures[@structure_id]
    after_structure_update
  end

  def load_previous
    load_structure((@structure_id - 1) % @structure_count)
  end

  def load_next
    load_structure((@structure_id + 1) % @structure_count)
  end

  def new_structure
    @structure_id = -1
    @structure = nil
    after_size_update
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

  def toolbar_icon(letter, index)
    Tile.for_letter(letter).tap { |result|
      result.x = 24 * index
      result.y = 24
    }
  end

  def draw_toolbar(args)
    args.outputs.primitives << toolbar
    return if @structure_id == -1

    args.outputs.primitives << [13 * 24, 48, @structure_id.to_s, 255, 255, 255].label
  end
end
