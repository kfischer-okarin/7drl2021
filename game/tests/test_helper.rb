module TestHelper
  class << self
    def clear_keyboard(args)
      args.inputs.keyboard.key_down.clear
    end

    def simulate_keypress(args, *keys)
      clear_keyboard(args)
      args.inputs.keyboard.key_down.set keys
    end

    def tile_attributes(tile, *additional_attributes, **merged_attributes)
      tile.slice(:path, :source_x, :source_y, :source_w, :source_h, :w, :h, *additional_attributes)
          .merge(merged_attributes)
    end
  end
end

module GTK
  class Assert
    def primitive_with!(primitive_attributes, primitive_array, message = nil)
      @assertion_performed = true
      return if primitive_array.any? { |primitive|
        primitive_attributes.keys.all? { |attribute|
          primitive.send(attribute) == primitive_attributes[attribute]
        }
      }

      raise "Expected #{primitive_array.inspect} to contain a primitive with attributes #{primitive_attributes}.\n#{message}"
    end
  end
end
