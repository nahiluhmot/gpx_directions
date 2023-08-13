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

    def calculate_directions(osm_map, gpx_route)
      Logger.info("building 2D tree with #{osm_map.nodes.length} nodes")
      node_tree = TwoDimensionalTree.build(osm_map.nodes)

      Logger.info("matching #{gpx_route.points.length} points to nodes")
      slice_size = (gpx_route.points.length / Parallel.processor_count) + 1
      matching_nodes = Parallel.flat_map(gpx_route.points.each_slice(slice_size)) do |slice|
        slice.map { |point| node_tree.find_nearest_node(point.lat, point.lon) }
      end

      Logger.info("matching nodes to #{osm_map.ways.length} ways")
      node_ways = WayMatcher
        .build(osm_map.ways)
        .match_node_ways(matching_nodes)

      Logger.info("translating node ways to directions")
      DirectionsCalculator.calculate_directions(node_ways)
    end
  end
end
