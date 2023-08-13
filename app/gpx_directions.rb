require "bigdecimal"
require "bigdecimal/util"
require "logger"

require "bzip2/ffi"
require "ox"
require "parallel"
require "sums_up"
require "sqlite3"

require "gpx_directions/sax"

require "gpx_directions/calculators"
require "gpx_directions/db"
require "gpx_directions/gpx"
require "gpx_directions/osm"
require "gpx_directions/serializers"

# Top-level functions.
module GpxDirections
  Logger = ::Logger.new($stderr).tap do |logger|
    logger.formatter = proc do |severity, datetime, progname, msg|
      "#{severity[0]} #{datetime.iso8601(3)} #{msg}\n"
    end
    logger.level = :info
  end

  class << self
    def generate_directions(db_filepath:, gpx_filepath:)
      gpx_route = load_gpx_route(gpx_filepath)
      bounds_ary = calculate_route_clusters(gpx_route)
      osm_map = load_osm_map_from_db(db_filepath, bounds_ary)
      directions = calculate_directions(osm_map, gpx_route)

      Serializers.show_directions(directions)
    end

    def seed_db(db_filepath:, osm_filepath:)
      osm_map = load_osm_map_from_file(osm_filepath)

      Logger.info("seeding db at #{db_filepath}")

      DB
        .build(db_filepath)
        .seed_db(osm_map)
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

    def load_osm_map_from_file(path)
      Logger.info("parsing osm file at #{path}")

      osm_map = File
        .open(path, &Osm.method(:parse_xml))
        .then(&Osm.method(:build_map))

      Logger.info("parsed osm map #{Serializers.show_map(osm_map)}")

      osm_map
    end

    def load_osm_map_from_db(path, bounds_ary, padding: BigDecimal("0.0005"))
      Logger.info("loading map from #{path}")

      padded_bounds_ary = bounds_ary.map do |bounds|
        Calculators.add_padding_to_bounds(bounds, padding)
      end

      osm_map = DB.build(path).build_map_for_bounds(*padded_bounds_ary)

      Logger.info("loaded osm map #{Serializers.show_map(osm_map)}")

      osm_map
    end

    def calculate_route_clusters(gpx_route)
      Logger.info("calculating route clusters for route with #{gpx_route.points.length} points")

      Calculators.calculate_route_clusters(gpx_route)
    end

    def calculate_directions(osm_map, gpx_route)
      Logger.info("calculating directions")

      directions = Calculators.calculate_directions(osm_map, gpx_route)

      Logger.info("calculated directions with #{directions.steps.count} steps")

      directions
    end
  end
end
