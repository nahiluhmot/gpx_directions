module GpxDirections
  class NodeMatcher
    def self.build(nodes, ways)
      nodes_by_id = nodes.to_h { |node| [node.id, node] }

      nodes_with_named_ways = []

      ways.each do |way|
        next unless way.name

        nodes_with_named_ways += nodes_by_id.values_at(*way.node_ids)
      end

      new(nodes_with_named_ways)
    end

    def initialize(nodes)
      @nodes = nodes
    end

    def find_matching_node(point)
      @nodes.min_by do |node|
        GpsCalculator.calculate_distance_meters(
          point.lat,
          point.lon,
          node.lat,
          node.lon
        )
      end
    end
  end
end
