require "bigdecimal"
require "logger"

require "bzip2/ffi"
require "ox"
require "sums_up"

require "gpx_directions/sax"

require "gpx_directions/calculators"
require "gpx_directions/gpx"
require "gpx_directions/osm"
require "gpx_directions/serializers"
require "gpx_directions/sorting"

# Top-level functions.
module GpxDirections
  module_function

  Logger = ::Logger.new($stderr).tap do |logger|
    logger.formatter = proc do |severity, datetime, progname, msg|
      "#{severity[0]} #{datetime.iso8601} #{msg}\n"
    end
  end

  def generate_directions(gpx_filepath:, osm_filepath:)
    Logger.info("parsing gpx file at #{gpx_filepath}")
    gpx_route = File
      .open(gpx_filepath, &Gpx.method(:parse_xml))
      .then(&Gpx.method(:build_route))

    Logger.info("parsing osm file at #{osm_filepath}")
    osm_map = File
      .open(osm_filepath, &Osm.method(:parse_xml))
      .then(&Osm.method(:build_map))

    Logger.info("calculating directions")
    directions = Calculators.calculate_directions(osm_map, gpx_route)

    Logger.info("serializing directions")
    Serializers.show_directions(directions)
  end
end
