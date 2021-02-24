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

    def clear_outputs(args)
      args.outputs.primitives.clear
      args.passes.each do |render_target|
        render_target.primitives.clear
      end
    end
  end
end

module GTK
  class Assert
    def primitive_was_rendered!(primitive_attributes, args, message = nil)
      @assertion_performed = true

      render_target_primitives = args.passes.map { |render_target|
        [render_target.target, render_target.primitives]
      }.to_h

      all_primitives = args.outputs.primitives.map { |primitive|
        path = primitive.path.to_s
        next primitive unless render_target_primitives.key?(path)

        render_target_primitives[path].map { |target_primitive|
          target_primitive.dup.tap { |translated|
            translated.x += primitive.x
            translated.y += primitive.y
          }
        }
      }.flatten(1)

      return if all_primitives.any? { |primitive|
        primitive_attributes.keys.all? { |attribute|
          primitive.respond_to?(attribute) && primitive.send(attribute) == primitive_attributes[attribute]
        }
      }

      primitive_array_string = "[\n  " + all_primitives.map(&:inspect).join(",\n  ") + "\n]"

      raise "Expected\n\n#{primitive_array_string}\n\nto contain a primitive with attributes #{primitive_attributes}.\n#{message}"
    end
  end
end
