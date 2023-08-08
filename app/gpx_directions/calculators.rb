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

    # Minimum and maximum bounds for latitude and longitude.
    LatLonConstraints = Struct.new(
      :min_lat,
      :max_lat,
      :min_lon,
      :max_lon,
      keyword_init: true
    )

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

    def calculate_route_constraints(gpx_route)
      constraints = LatLonConstraints.new
      points = gpx_route.points

      constraints.min_lat, constraints.max_lat = points.minmax_by(&:lat).map(&:lat)
      constraints.min_lon, constraints.max_lon = points.minmax_by(&:lon).map(&:lon)

      constraints
    end

    def add_padding_to_constraint(padding, constraint)
      LatLonConstraints.new(
        min_lat: constraint.min_lat - padding,
        max_lat: constraint.max_lat + padding,
        min_lon: constraint.min_lon - padding,
        max_lon: constraint.max_lon + padding
      )
    end
  end
end
