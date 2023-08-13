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
  Logger = ::Logger.new($stderr).tap do |logger|
    logger.formatter = proc do |severity, datetime, progname, msg|
      "#{severity[0]} #{datetime.iso8601(3)} #{msg}\n"
    end
    logger.level = :info
  end

  class << self
    def generate_directions(db_filepath:, gpx_filepath:)
      gpx_route = load_gpx_route(gpx_filepath)
      osm_map = load_osm_map_from_db(db_filepath, gpx_route)
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

    def load_osm_map_from_db(path, gpx_route, padding_meters: 100)
      Logger.info("loading map from #{path}")

      slice_size = ((gpx_route.points.length - 1) / Parallel.processor_count) + 1
      osm_maps = Parallel.flat_map(gpx_route.points.each_slice(slice_size)) do |points|
        padded_bounds_ary = Calculators.calculate_bounds_around_points(points, padding_meters)

        DB.build(path).build_map_for_bounds(padded_bounds_ary)
      end

      Logger.info("merging #{osm_maps.length} maps")
      osm_map = Osm.merge_maps(osm_maps)

      Logger.info("loaded osm map #{Serializers.show_map(osm_map)}")

      osm_map
    end

    def calculate_directions(osm_map, gpx_route)
      Logger.info("calculating directions")

      Logger.info("building 2D tree with #{osm_map.nodes.length} nodes")
      node_tree = Calculators.build_2d_tree(osm_map.nodes)

      Logger.info("matching #{gpx_route.points.length} points to nodes")
      slice_size = ((gpx_route.points.length - 1) / Parallel.processor_count) + 1
      matching_nodes = Parallel.flat_map(gpx_route.points.each_slice(slice_size)) do |slice|
        slice.map { |point| node_tree.find_nearest_node(point.lat, point.lon) }
      end

      Logger.info("matching nodes to #{osm_map.ways.length} ways")
      node_ways = Calculators.match_nodes_to_ways(matching_nodes, osm_map.ways)

      Logger.info("translating #{node_ways.length} node ways to directions")
      directions = Calculators.calculate_directions(node_ways)
      Logger.info("calculated directions with #{directions.steps.count} steps")

      directions
    end
  end
end
