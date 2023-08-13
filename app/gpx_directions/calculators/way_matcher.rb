module GpxDirections
  module Calculators
    # Associate Osm::Nodes with Osm::Ways assuming the nodes are on a continuous
    # path.
    class WayMatcher
      def self.build(ways)
        ways_by_node_id = {}

        ways.each do |way|
          way.node_ids.each do |node_id|
            ways_by_node_id[node_id] ||= []
            ways_by_node_id[node_id] << way
          end
        end

        new(ways_by_node_id)
      end

      def initialize(ways_by_node_id)
        @ways_by_node_id = ways_by_node_id
      end

      def match_nodes_to_ways(nodes)
        nodes.each_with_object([]) do |node, node_ways|
          ways = @ways_by_node_id[node.id]
          last_node_id = node_ways.last&.way&.id

          way = ways.find { |way| way.id == last_node_id } if last_node_id
          way ||= ways.first

          node_ways << NodeWay.new(node:, way:)
        end
      end
    end
  end
end
