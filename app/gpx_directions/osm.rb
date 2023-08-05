module GpxDirections
  # Data structures, helper functions, and service objects related to
  # OpenStreetMap.
  module Osm
    # Parses .osm files downloaded from OpenStreetMap.
    Parser = SaxDSL.define(
      root: {
        children: [:osm]
      },
      osm: {
        children: [:bounds, :node, :way]
      },
      bounds: {
        attrs: [:minlat, :minlon, :maxlat, :maxlon]
      },
      node: {
        attrs: [:id, :lat, :lon]
      },
      way: {
        attrs: [:id],
        children: [:nd, :tag]
      },
      nd: {
        attrs: [:ref]
      },
      tag: {
        attrs: [:k, :v]
      }
    )

    # Top-level Map hierarchy.
    Map = Struct.new(:bounds, :nodes, :ways, keyword_init: true)

    # GPS Bounds of a Map.
    Bounds = Struct.new(:minlat, :minlon, :maxlat, :maxlon, keyword_init: true)

    # An XY coordinate on a Map.
    Node = Struct.new(:id, :lat, :lon, keyword_init: true)

    # A Way (e.g. "Main Street", "I-85") on a Map.
    Way = Struct.new(:id, :name, :node_ids, keyword_init: true)

    module_function

    # Parsers

    def parse(io)
      Parser.parse(io)
    end

    # Builders

    def build_map(parse_root)
      parse_osm = parse_root.osm.first

      bounds = build_bounds(parse_osm.bounds.first)
      ways = build_ways(parse_osm.way)

      node_ids = calculate_node_ids(ways)
      nodes = build_nodes(parse_osm.node, node_ids)

      Map.new(bounds:, nodes:, ways:)
    end

    def build_bounds(parse_bounds)
      minlat = BigDecimal(parse_bounds.minlat)
      minlon = BigDecimal(parse_bounds.minlon)
      maxlat = BigDecimal(parse_bounds.maxlat)
      maxlon = BigDecimal(parse_bounds.maxlon)

      Bounds.new(minlat:, minlon:, maxlat:, maxlon:)
    end

    def build_nodes(parse_nodes, node_ids)
      parse_nodes
        .map(&method(:build_node))
        .select! { |node| node_ids.member?(node.id) }
    end

    def build_node(parse_node)
      id = parse_node.id.to_sym
      lat = BigDecimal(parse_node.lat)
      lon = BigDecimal(parse_node.lon)

      Node.new(id:, lat:, lon:)
    end

    def build_ways(parse_ways)
      parse_ways
        .map(&method(:build_way))
        .select!(&:name)
    end

    def build_way(parse_way)
      id = parse_way.id.to_sym
      name = parse_way.tag&.find { |tag| tag.k == "name" }&.v
      node_ids = parse_way.nd.map(&:ref).map!(&:to_sym)

      Way.new(id:, name:, node_ids:)
    end

    # Helpers

    def calculate_node_ids(ways)
      ways.each_with_object(Set.new) do |way, set|
        way.node_ids.each(&set.method(:add))
      end
    end
  end
end
