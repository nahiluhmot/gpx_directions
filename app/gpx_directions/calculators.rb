require "gpx_directions/calculators/coordinate_math"
require "gpx_directions/calculators/directions_calculator"
require "gpx_directions/calculators/sorting"
require "gpx_directions/calculators/two_dimensional_tree"
require "gpx_directions/calculators/way_matcher"

module GpxDirections
  # Business logic for the app.
  module Calculators
    # Directions are a sequence of Steps.
    Directions = Struct.new(:steps, keyword_init: true)

    # Different kinds of Steps.
    Step = SumsUp.define(
      start_on: :node,
      continue_on: [:way, :meters],
      turn: [:turn, :way],
      finish_on: :node
    )

    # Human-understandable Turn descriptions.
    Turn = SumsUp.define(
      :sharp_left,
      :left,
      :straight,
      :right,
      :sharp_right
    )

    # An OpenStreetMap Node matched to one of its Ways.
    NodeWay = Struct.new(:node, :way, keyword_init: true)

    # Minimum and maximum bounds for latitude and longitude.
    Bounds = Struct.new(
      :min_lat,
      :max_lat,
      :min_lon,
      :max_lon,
      keyword_init: true
    )

    module_function

    # Builders

    def build_2d_tree(nodes)
      TwoDimensionalTree.build(nodes)
    end

    # Helpers

    def calculate_bounds_around_points(points, padding_meters)
      points.map do |point|
        CoordinateMath.calculate_bounds_around_point(point, padding_meters)
      end
    end

    def match_nodes_to_ways(nodes, ways)
      WayMatcher.build(ways).match_nodes_to_ways(nodes)
    end

    def calculate_directions(node_ways)
      DirectionsCalculator.calculate_directions(node_ways)
    end
  end
end
