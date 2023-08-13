require "bigdecimal"
require "bigdecimal/math"
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
  module_function

  def generate_directions(db_filepath:, gpx_filepath:)
    gpx_route = load_gpx_route(gpx_filepath:)
    osm_map = load_osm_map_from_db(db_filepath:, gpx_route:)
    directions = calculate_directions(osm_map:)

    Serializers.show_directions(directions)
  end

  def seed_db(db_filepath:, osm_filepath:)
    osm_map = load_osm_map_from_file(osm_filepath:)

    logger.info("seeding db at #{db_filepath}")

    db = DB.build(db_filepath)

    db.seed_db(osm_map)
  end

  def load_gpx_route(gpx_filepath:)
    logger.info("parsing gpx file at #{gpx_filepath}")

    gpx_route = File
      .open(gpx_filepath, &Gpx.method(:parse_xml))
      .then(&Gpx.method(:build_route))

    logger.info("parsed route #{Serializers.show_route(gpx_route)}")

    gpx_route
  end

  def load_osm_map_from_file(osm_filepath:)
    logger.info("parsing osm file at #{osm_filepath}")

    osm_map = File
      .open(osm_filepath, &Osm.method(:parse_xml))
      .then(&Osm.method(:build_map))

    logger.info("parsed osm map #{Serializers.show_map(osm_map)}")

    osm_map
  end

  # The loaded OSM Map only contains the GPX Route's nodes in order.
  def load_osm_map_from_db(db_filepath:, gpx_route:, padding_meters: 750)
    logger.info("loading map from #{db_filepath}")
    db = DB.build(db_filepath)

    slice_size = ((gpx_route.points.length - 1) / (Parallel.processor_count * 4)) + 1
    osm_maps = Parallel.map(gpx_route.points.each_slice(slice_size)) do |points|
      padded_bounds_ary = Calculators.calculate_bounds_around_points(points, padding_meters)
      osm_map = db.build_map_for_bounds(padded_bounds_ary)

      node_tree = Calculators.build_2d_tree(osm_map.nodes)
      osm_map.nodes = points.map do |point|
        node_tree.find_nearest_node(point.lat, point.lon)
      end

      osm_map
    end

    logger.info("merging #{osm_maps.length} maps")
    osm_map = Osm.merge_maps(osm_maps)

    logger.info("loaded osm map #{Serializers.show_map(osm_map)}")

    osm_map
  end

  def calculate_directions(osm_map:)
    logger.info("matching nodes to #{osm_map.ways.length} ways")
    node_ways = Calculators.match_nodes_to_ways(osm_map.nodes, osm_map.ways)

    logger.info("translating #{node_ways.length} node ways to directions")
    directions = Calculators.calculate_directions(node_ways)
    logger.info("calculated directions with #{directions.steps.count} steps")

    directions
  end

  def logger
    @logger ||= ::Logger.new($stderr).tap do |logger|
      logger.formatter = proc do |severity, datetime, progname, msg|
        "#{severity[0]} #{datetime.iso8601(3)} #{msg}\n"
      end
      logger.level = ENV["GPX_DIRECTIONS_LOG_LEVEL"] || :warn
    end
  end
end
