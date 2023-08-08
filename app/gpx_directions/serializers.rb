module GpxDirections
  # Pretty printers for domain objects.
  module Serializers
    module_function

    def show_constraints(constraints)
      "{lat: %f..%f, lon: %f..%f}" % [
        constraints.min_lat,
        constraints.max_lat,
        constraints.min_lon,
        constraints.max_lon
      ]
    end

    def show_route(route)
      "{start: %s, end: %s}" % [
        show_point(route.points.first),
        show_point(route.points.last)
      ]
    end

    def show_point(point)
      "{lat: %f, lon: %f}" % [point.lat, point.lon]
    end

    def show_directions(directions)
      directions
        .steps
        .map(&method(:show_step))
        .join("\n")
    end

    def show_map(map)
      "{nodes: #{map.nodes.count}, ways: #{map.ways.count}, bounds: #{show_constraints(map.bounds)}}"
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
        m.start_on { |node| "Start at #{show_point(node)}" }
        m.continue_on do |way, meters|
          "Continue on #{way.name} for #{show_meters(meters)}"
        end
        m.turn { |turn, way| "#{show_turn(turn)} onto #{way.name}" }
        m.finish_on { |node| "Finish on #{show_point(node)}" }
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
  end
end
