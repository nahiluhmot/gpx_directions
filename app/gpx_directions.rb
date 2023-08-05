require "bigdecimal"

require "ox"
require "sums_up"

require "gpx_directions/sax"

require "gpx_directions/gpx"
require "gpx_directions/osm"

require "gpx_directions/gps_calculator"
require "gpx_directions/node_matcher"
require "gpx_directions/route_builder"
require "gpx_directions/way_matcher"

# Top-level functions.
module GpxDirections
  module_function

  def generate_directions(osm_filepath:, gpx_filepath:)
    osm_map = File
      .open(osm_filepath, &Osm.method(:parse_xml))
      .then(&Osm.method(:build_map))

    gpx_route = File
      .open(gpx_filepath, &Gpx.method(:parse_xml))
      .then(&Gpx.method(:build_route))

    matching_nodes = NodeMatcher
      .new(osm_map.nodes)
      .then { |matcher| gpx_route.points.map(&matcher.method(:find_matching_node)) }

    node_ways = WayMatcher
      .build(osm_map.ways)
      .build_node_ways(matching_nodes)

    RouteBuilder
      .build_directions(node_ways)
      .then(&RouteBuilder.method(:show_directions))
  end
end
