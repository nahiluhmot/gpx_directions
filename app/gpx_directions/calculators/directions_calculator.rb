module GpxDirections
  module Calculators
    # Builds Directions from a sequence of NodeWays.
    module DirectionsCalculator
      module_function

      def calculate_directions(node_ways)
        all_steps = calculate_steps(node_ways)
        steps = reduce_redundant_steps(all_steps)

        Directions.new(steps:)
      end

      def calculate_steps(node_ways)
        steps = []

        start = node_ways.first
        steps << Step.start_on(node_ways.first)

        iterator = [start, start].to_enum + node_ways.to_enum
        iterator.each_cons(3) do |last_node_way, curr_node_way, next_node_way|
          next_steps = calculate_next_steps(last_node_way, curr_node_way, next_node_way)

          steps.concat(next_steps)
        end

        steps << Step.finish_on(node_ways.last.node)

        steps
      end

      def calculate_next_steps(last_node_way, curr_node_way, next_node_way)
        next_steps = []

        if curr_node_way.way.id != next_node_way.way.id
          next_steps << Step.turn(
            calculate_turn(
              CoordinateMath.calculate_turn_degrees(
                last_node_way.node,
                curr_node_way.node,
                next_node_way.node
              )
            ),
            next_node_way.way
          )
        end

        if curr_node_way.node.id != next_node_way.node.id
          next_steps << Step.continue_on(
            next_node_way.way,
            CoordinateMath.calculate_distance_meters(
              curr_node_way.node.lat,
              curr_node_way.node.lon,
              next_node_way.node.lat,
              next_node_way.node.lon
            )
          )
        end

        next_steps
      end

      def calculate_turn(degrees)
        if degrees <= 85
          Turn.sharp_left
        elsif degrees <= 170
          Turn.left
        elsif degrees <= 190
          Turn.straight
        elsif degrees <= 275
          Turn.right
        else
          Turn.sharp_right
        end
      end

      def reduce_redundant_steps(steps)
        steps.each_with_object([]) do |step, result|
          prev_part = result.last

          if step.continue_on? && prev_part&.continue_on? && (prev_part.way.id == step.way.id)
            prev_part.meters += step.meters
          else
            result << step
          end
        end
      end
    end
  end
end
