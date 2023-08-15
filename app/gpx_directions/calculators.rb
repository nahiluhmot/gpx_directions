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

    def calculate_bounds_around_points(gpx_points, padding_meters)
      gpx_points.map do |gpx_point|
        CoordinateMath.calculate_bounds_around_point(gpx_point, padding_meters)
      end
    end

    def calculate_osm_map_for_gpx_route(gpx_route, osm_map)
      node_tree = TwoDimensionalTree.build(osm_map.nodes)
      nodes = gpx_route.points.map do |gpx_point|
        node_tree.find_nearest_node(gpx_point.lat, gpx_point.lon)
      end

      Osm::Map.new(nodes:, ways: osm_map.ways)
    end

    def match_nodes_to_ways(osm_nodes, osm_ways)
      WayMatcher.build(osm_ways).match_nodes_to_ways(osm_nodes)
    end

    def calculate_directions(node_ways)
      DirectionsCalculator.calculate_directions(node_ways)
    end
  end
end
