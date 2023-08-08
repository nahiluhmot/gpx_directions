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

  DEFAULT_PADDING = BigDecimal("0.1")

  Logger = ::Logger.new($stderr).tap do |logger|
    logger.formatter = proc do |severity, datetime, progname, msg|
      "#{severity[0]} #{datetime.iso8601} #{msg}\n"
    end
  end

  class << self
    def generate_directions(gpx_filepath:, osm_filepath:)
      gpx_route = load_gpx_route(gpx_filepath)
      constraints = calculate_route_constraints(gpx_route)
      osm_map = load_osm_map(osm_filepath, constraints)
      directions = calculate_directions(osm_map, gpx_route)

      Serializers.show_directions(directions)
    end

    private

    def load_gpx_route(path)
      Logger.info("parsing gpx file at #{path}")

      gpx_route = File
        .open(path, &Gpx.method(:parse_xml))
        .then(&Gpx.method(:build_route))

      Logger.info("parsed route #{Serializers.show_route(gpx_route)}")

      gpx_route
    end

    def load_osm_map(path, _constraints)
      Logger.info("parsing osm file at #{path}")

      osm_map = File
        .open(path, &Osm.method(:parse_xml))
        .then(&Osm.method(:build_map))

      Logger.info("parsed osm map #{Serializers.show_map(osm_map)}")

      osm_map
    end

    def calculate_directions(osm_map, gpx_route)
      Logger.info("calculating directions")

      directions = Calculators.calculate_directions(osm_map, gpx_route)

      Logger.info("calculated directions with #{directions.steps.count} steps")

      directions
    end

    def calculate_route_constraints(gpx_route)
      Logger.info("calculating route bounds")

      constraints = Calculators
        .calculate_route_constraints(gpx_route)
        .then { |c| Calculators.add_padding_to_constraint(DEFAULT_PADDING, c) }

      Logger.info("calculated route bounds #{Serializers.show_constraints(constraints)}")

      constraints
    end
  end
end
