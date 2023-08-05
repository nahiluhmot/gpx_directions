module GpxDirections
  # Builds Directions from WayMather::NodeWays.
  module RouteBuilder
    # Directions are a sequence of Steps.
    Directions = Struct.new(:steps, keyword_init: true)

    # Different kinds of route steps.
    Step = SumsUp.define(
      start_on: :node,
      continue_on: [:way, :meters],
      turn: [:turn, :way],
      finish_on: :node
    )

    # Human-readable Turn descriptions.
    Turn = SumsUp.define(
      :sharp_left,
      :left,
      :straight,
      :right,
      :sharp_right
    )

    module_function

    # Builders

    def build_directions(node_ways)
      all_steps = build_steps(node_ways)
      steps = reduce_redundant_steps(all_steps)

      Directions.new(steps:)
    end

    def build_steps(node_ways)
      start = node_ways.first

      iterator = [start, start].to_enum + node_ways.to_enum
      steps = [Step.start_on(start)]

      iterator.each_cons(3) do |last_node_way, node_way1, node_way2|
        if node_way1.way.id != node_way2.way.id
          steps << Step.turn(
            build_turn(
              GpsCalculator.calculate_turn_degrees(
                last_node_way.node,
                node_way1.node,
                node_way2.node
              )
            ),
            node_way2.way
          )
        end

        if node_way1.node.id != node_way2.node.id
          steps << Step.continue_on(
            node_way2.way,
            GpsCalculator.calculate_distance_meters(
              node_way1.node.lat,
              node_way1.node.lon,
              node_way2.node.lat,
              node_way2.node.lon
            )
          )
        end
      end

      steps << Step.finish_on(node_ways.last.node)

      steps
    end

    def build_turn(degrees)
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

    # Serializers

    def show_directions(directions)
      directions
        .steps
        .map(&method(:show_step))
        .join("\n")
    end

    def show_meters(meters)
      if meters > 1000
        "#{(meters / 1000).round(1)}km"
      else
        "#{meters.round}m"
      end
    end

    def show_step(step)
      step.match do |m|
        m.start_on "Start"
        m.continue_on do |way, meters|
          "Continue on #{way.name} for #{show_meters(meters)}"
        end
        m.turn { |turn, way| "#{show_turn(turn)} onto #{way.name}" }
        m.finish_on "Finish"
      end
    end

    def show_turn(turn)
      turn.match(
        sharp_left: "Take a sharp left",
        left: "Turn left",
        straight: "Continue straight",
        right: "Turn right",
        sharp_right: "Take a sharp right"
      )
    end

    # Helpers

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
