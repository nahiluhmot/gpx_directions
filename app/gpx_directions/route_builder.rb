module GpxDirections
  module RouteBuilder
    TurnDescription = SumsUp.define(
      :sharp_left,
      :left,
      :straight,
      :right,
      :sharp_right
    ) do
      def show
        match(
          sharp_left: "Take a sharp left",
          left: "Turn left",
          straight: "Continue straight",
          right: "Turn right",
          sharp_right: "Take a sharp right",
        )
      end
    end

    RoutePart = SumsUp.define(
      start_on: :node,
      continue_on: [:way, :meters],
      turn: [:way, :turn_description],
      finish_on: :node
    ) do
      def show
        match do |m|
          m.start_on "Start"
          m.continue_on do |way, meters|
            distance =
              if meters > 1000
                "#{(meters / 1000).round(1)}km"
              else
                "#{meters.round}m"
              end

            "Continue on #{way.name || "?"} for #{distance}"
          end
          m.turn do |way|
            "#{turn_description.show} onto #{way.name || "?"}"
          end
          m.finish_on "Finish"
        end
      end
    end

    module_function

    def build_route(node_ways)
      return [] if node_ways.empty?

      route_parts = build_route_with_redundant_parts(node_ways)

      reduce_redundant_parts(route_parts)
    end

    def build_route_with_redundant_parts(node_ways)
      start = node_ways.first
      iterator = [start, start].to_enum + node_ways.to_enum
      route_parts = [RoutePart.start_on(start)]

      iterator.each_cons(3) do |last_node_way, node_way1, node_way2|
        if node_way1.way.id != node_way2.way.id
          route_parts << RoutePart.turn(
            node_way2.way,
            calculate_turn_description(
              GpsCalculator.calculate_turn_degrees(
                last_node_way.node,
                node_way1.node,
                node_way2.node
              )
            )
          )
        end

        if node_way1.node.id != node_way2.node.id
          route_parts << RoutePart.continue_on(
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

      route_parts << RoutePart.finish_on(node_ways.last.node)
    end

    def reduce_redundant_parts(route_parts)
      route_parts.each_with_object([]) do |route_part, result|
        prev_part = result.last

        if route_part.continue_on? && prev_part&.continue_on? && (prev_part.way.id == route_part.way.id)
          prev_part.meters += route_part.meters
        else
          result << route_part
        end
      end
    end

    def calculate_turn_description(degrees)
      if degrees <= 85
        TurnDescription.sharp_left
      elsif degrees <= 170
        TurnDescription.left
      elsif degrees <= 190
        TurnDescription.straight
      elsif degrees <= 275
        TurnDescription.right
      else
        TurnDescription.sharp_right
      end
    end
  end
end
