module GpxDirections
  # Pretty printers for domain objects.
  module Serializers
    module_function

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
  end
end
