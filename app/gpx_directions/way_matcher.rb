module GpxDirections
  class WayMatcher
    NodeWay = Struct.new(:node, :way, keyword_init: true)

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

    def build_node_ways(nodes)
      nodes.each_with_object([]) do |node, node_ways|
        ways = @ways_by_node_id[node.id]
        last_node_id = node_ways.last&.way&.id

        way =
          if ways.empty?
            nil
          elsif ways.length == 1
            ways.first
          elsif (matching = ways.find { |way| way.id == last_node_id })
            matching
          else
            ways.first
          end

        node_ways << NodeWay.new(node:, way:)
      end
    end
  end
end
