require "bigdecimal"

require "ox"
require "sums_up"

require "gpx_directions/sax"

require "gpx_directions/calculators"
require "gpx_directions/gpx"
require "gpx_directions/osm"
require "gpx_directions/serializers"

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

    directions = Calculators.calculate_directions(osm_map, gpx_route)

    Serializers.show_directions(directions)
  end
end
