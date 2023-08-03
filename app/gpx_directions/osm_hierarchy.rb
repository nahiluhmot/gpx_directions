module GpxDirections
  OsmHierarchy = Struct.new(:minlat, :minlon, :maxlat, :maxlon, :nodes, :ways, keyword_init: true) do
    Node = Struct.new(:id, :lat, :lon, keyword_init: true)
    Way = Struct.new(:id, :name, :node_ids, keyword_init: true)

    def self.build(parse_root)
      parse_osm = parse_root.osm.first
      parse_bounds = parse_osm.bounds.first
      parse_nodes = parse_osm.node
      parse_ways = parse_osm.way

      new(
        minlat: BigDecimal(parse_bounds.minlat),
        minlon: BigDecimal(parse_bounds.minlon),
        maxlat: BigDecimal(parse_bounds.maxlat),
        maxlon: BigDecimal(parse_bounds.maxlon),
        nodes: parse_nodes
          .map do |parse_node|
            Node.new(
              id: parse_node.id.to_sym,
              lat: BigDecimal(parse_node.lat),
              lon: BigDecimal(parse_node.lon)
            )
          end
          .sort_by(&:lat),
        ways: parse_ways.map do |parse_way|
          Way.new(
            id: parse_way.id.to_sym,
            name: parse_way.tag&.find { |tag| tag.k == "name" }&.v,
            node_ids: parse_way.nd.map(&:ref).map(&:to_sym)
          )
        end
      )
    end

    def nodes_by_id
      @nodes_by_id ||= nodes.to_h { |node| [node.id, node] }
    end

    def ways_by_id
      @ways_by_id ||= ways.to_h { |way| [way.id, way] }
    end

    def ways_by_node_id
      return @ways_by_node_id if @ways_by_node_id

      hash = {}

      ways.each do |way|
        way.node_ids.each do |node_id|
          hash[node_id] ||= []

          hash[node_id] << way
        end
      end

      @ways_by_node_id = hash
    end
  end
end
