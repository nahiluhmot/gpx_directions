module GpxDirections
  OsmHierarchy = Struct.new(:minlat, :minlon, :maxlat, :maxlon, :nodes, :ways, keyword_init: true) do
    Node = Struct.new(:id, :lat, :lon, keyword_init: true)
    Way = Struct.new(:id, :name, :node_ids, keyword_init: true)

    def self.build(parse_root)
      parse_osm = parse_root.osm.first
      parse_bounds = parse_osm.bounds.first

      ways = parse_osm
        .way
        .map do |parse_way|
          Way.new(
            id: parse_way.id.to_sym,
            name: parse_way.tag&.find { |tag| tag.k == "name" }&.v,
            node_ids: parse_way.nd.map(&:ref).map(&:to_sym)
          )
        end
        .select!(&:name)

      node_ids = ways.each_with_object(Set.new) { |way, set| way.node_ids.each(&set.method(:add)) }
      nodes = parse_osm
        .node
        .map do |parse_node|
          Node.new(
            id: parse_node.id.to_sym,
            lat: BigDecimal(parse_node.lat),
            lon: BigDecimal(parse_node.lon)
          )
        end
        .select! { |node| node_ids.member?(node.id) }

      new(
        minlat: BigDecimal(parse_bounds.minlat),
        minlon: BigDecimal(parse_bounds.minlon),
        maxlat: BigDecimal(parse_bounds.maxlat),
        maxlon: BigDecimal(parse_bounds.maxlon),
        nodes:,
        ways:
      )
    end
  end
end
