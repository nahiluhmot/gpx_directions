require "gpx_directions/calculators/coordinate_math"
require "gpx_directions/calculators/two_dimensional_tree"
require "gpx_directions/calculators/way_matcher"
require "gpx_directions/calculators/directions_calculator"

module GpxDirections
  # Business logic for the app.
  module Calculators
    module_function

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

    def calculate_directions(osm_map, gpx_route)
      node_tree = TwoDimensionalTree.build(osm_map.nodes)

      matching_nodes = gpx_route.points.map do |point|
        node_tree.find_nearest_node(point.lat, point.lon)
      end

      node_ways = WayMatcher
        .build(osm_map.ways)
        .match_node_ways(matching_nodes)

      DirectionsCalculator.calculate_directions(node_ways)
    end
  end
end
