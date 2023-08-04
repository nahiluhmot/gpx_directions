require "bigdecimal"

require "ox"
require "sums_up"

require "gpx_directions/sax_dsl"
require "gpx_directions/sax_parser"

require "gpx_directions/gpx_parser"
require "gpx_directions/osm_parser"

require "gpx_directions/gpx_hierarchy"
require "gpx_directions/osm_hierarchy"

require "gpx_directions/gps_calculator"
require "gpx_directions/node_matcher"
require "gpx_directions/route_builder"
require "gpx_directions/way_matcher"

module GpxDirections
  module_function

  def calculate_route(osm_file:, gpx_file:)
    osm_hierarchy = build_hierarchy_from_file(osm_file, OsmParser, OsmHierarchy)
    gpx_hierarchy = build_hierarchy_from_file(gpx_file, GpxParser, GpxHierarchy)

    nodes = NodeMatcher
      .build(osm_hierarchy.nodes, osm_hierarchy.ways)
      .then { |matcher| gpx_hierarchy.points.map(&matcher.method(:find_matching_node)) }

    node_ways = WayMatcher
      .build(osm_hierarchy.ways)
      .build_node_ways(nodes)

    RouteBuilder.build_route(node_ways)
  end

  def build_hierarchy_from_file(file, parser, builder)
    File
      .open(file, &parser.method(:parse))
      .then(&builder.method(:build))
  end
end
