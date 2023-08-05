module GpxDirections
  class NodeMatcher
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
