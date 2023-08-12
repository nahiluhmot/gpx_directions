require "gpx_directions/calculators/coordinate_math"
require "gpx_directions/calculators/k_means"
require "gpx_directions/calculators/two_dimensional_tree"
require "gpx_directions/calculators/way_matcher"
require "gpx_directions/calculators/directions_calculator"

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
      matching_nodes = gpx_route
        .points
        .map { |point| node_tree.find_nearest_node(point.lat, point.lon) }

      Logger.info("matching nodes to #{osm_map.ways.length} ways")
      node_ways = WayMatcher
        .build(osm_map.ways)
        .match_node_ways(matching_nodes)

      Logger.info("translating node ways to directions")
      DirectionsCalculator.calculate_directions(node_ways)
    end

    def calculate_route_clusters(gpx_route)
      bounds = calculate_route_bounds(gpx_route)
      meters = CoordinateMath.calculate_distance_meters(
        bounds.min_lat,
        bounds.min_lon,
        bounds.max_lat,
        bounds.max_lon
      )
      km = (meters / 1000).round(1)
      k = (km / 2).floor.clamp(1, Float::INFINITY)

      Logger.info("calcuting #{k} clusters for route with bounds diagonal #{km}km")
      KMeans.new.k_means(k, gpx_route.points)
    end

    def calculate_route_bounds(gpx_route)
      bounds = Bounds.new
      points = gpx_route.points

      bounds.min_lat, bounds.max_lat = points.minmax_by(&:lat).map(&:lat)
      bounds.min_lon, bounds.max_lon = points.minmax_by(&:lon).map(&:lon)

      bounds
    end

    def add_padding_to_bounds(bounds, padding)
      Bounds.new(
        min_lat: bounds.min_lat - padding,
        max_lat: bounds.max_lat + padding,
        min_lon: bounds.min_lon - padding,
        max_lon: bounds.max_lon + padding
      )
    end
  end
end
