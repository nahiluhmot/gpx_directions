require "bigdecimal"

require "ox"
require "sums_up"

require "gpx_directions/sax_dsl"
require "gpx_directions/sax_parser"

require "gpx_directions/gpx_parser"
require "gpx_directions/osm_parser"

require "gpx_directions/gpx_hierarchy"
require "gpx_directions/osm_hierarchy"

require "gpx_directions/route_calculator"

module GpxDirections
  module_function

  def calculate_route(osm_file:, gpx_file:)
    osm_hierarchy = build_hierarchy_from_file(osm_file, OsmParser, OsmHierarchy)
    gpx_hierarchy = build_hierarchy_from_file(gpx_file, GpxParser, GpxHierarchy)

    RouteCalculator
      .new(osm_hierarchy)
      .calculate_route(gpx_hierarchy)
  end

  def build_hierarchy_from_file(file, parser, builder)
    File
      .open(file, &parser.method(:parse))
      .then(&builder.method(:build))
  end
end
