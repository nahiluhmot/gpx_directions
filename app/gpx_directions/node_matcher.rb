module GpxDirections
  # Associate Gpx::Points with Osm::Nodes.
  class NodeMatcher
    def initialize(nodes)
      @nodes = nodes
    end

    def find_matching_node(point)
      # TODO: refactor to use k-d tree.
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
