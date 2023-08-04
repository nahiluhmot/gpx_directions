module GpxDirections
  class RouteCalculator
    EARTH_RADIUS_METERS = 6_378_000
    ONE_DEGREE_RADIANS = Math::PI / 180

    NodeWay = Struct.new(:node, :way, keyword_init: true)

    TurnDescription = SumsUp.define(
      :sharp_left,
      :left,
      :straight,
      :right,
      :sharp_right
    ) do
      def show
        match(
          sharp_left: "Take a sharp left",
          left: "Turn left",
          straight: "Continue straight",
          right: "Turn right",
          sharp_right: "Take a sharp right",
        )
      end
    end

    RoutePart = SumsUp.define(
      start_on: :node,
      continue_on: [:way, :meters],
      turn: [:way, :turn_description],
      finish_on: :node
    ) do
      def show
        match do |m|
          m.start_on "Start"
          m.continue_on do |way, meters|
            distance =
              if meters > 1000
                "#{(meters / 1000).round(1)}km"
              else
                "#{meters.round}m"
              end

            "Continue on #{way&.name || '?'} for #{distance}"
          end
          m.turn do |way|
            "#{turn_description.show} onto #{way&.name || '?'}"
          end
          m.finish_on "Finish"
        end
      end
    end

    Route = Struct.new(:total_distance_meters, :route_parts, keyword_init: true)

    def initialize(osm_hierarchy)
      @osm_hierarchy = osm_hierarchy
    end

    def calculate_route(gpx_hierarchy)
      nodes = gpx_hierarchy.points.map(&method(:find_closest_node))
      node_ways = build_node_ways(nodes)

      route_parts = build_route(node_ways)

      reduce_redundant_parts(route_parts)
    end

    def find_closest_node(point)
      nodes_with_named_ways.min_by do |node|
        calculate_distance_meters(point.lat, point.lon, node.lat, node.lon)
      end
    end

    def build_node_ways(nodes)
      nodes.each_with_object([]) do |node, node_ways|
        ways = ways_by_node_id[node.id]
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

    def build_route(node_ways)
      return [] if node_ways.empty?
      return [RoutePart.finish_on(node_ways.first.node)] if node_ways.length == 1

      start, *, finish = node_ways

      route_parts = [RoutePart.start_on(start.node)]

      [start, *node_ways].each_cons(3) do |last_node_way, node_way1, node_way2|
        if node_way1.way.id != node_way2.way.id
          route_parts << RoutePart.turn(
            node_way2.way,
            calculate_turn_description(
              last_node_way.node,
              node_way1.node,
              node_way2.node
            )
          )
        end

        route_parts << RoutePart.continue_on(
          node_way2.way,
          calculate_distance_meters(
            node_way1.node.lat,
            node_way1.node.lon,
            node_way2.node.lat,
            node_way2.node.lon
          )
        )
      end

      route_parts << RoutePart.finish_on(finish.node)

      route_parts
    end

    def reduce_redundant_parts(route_parts)
      route_parts.each_with_object([]) do |route_part, result|
        prev_part = result.last

        if route_part.continue_on? && prev_part&.continue_on? && (prev_part.way.id == route_part.way.id)
          prev_part.meters += route_part.meters
        else
          result << route_part
        end
      end
    end

    def calculate_distance_meters(lat1, lon1, lat2, lon2)
      a = (Math.cos((lat2 - lat1) * ONE_DEGREE_RADIANS) / 2)
      b = (
        Math.cos(lat1 * ONE_DEGREE_RADIANS) *
        Math.cos(lat2 * ONE_DEGREE_RADIANS) *
        (1 - Math.cos((lon2 - lon1) * ONE_DEGREE_RADIANS)) /
        2
      )
      c = 0.5 - a + b

      2 * EARTH_RADIUS_METERS * Math.asin(Math.sqrt(c))
    end

    def calculate_turn_description(node1, node2, node3)
      return TurnDescription.straight if [node1, node2, node3].uniq.length != 3

      a = calculate_distance_meters(node1.lat, node1.lon, node2.lat, node2.lon)
      b = calculate_distance_meters(node2.lat, node2.lon, node3.lat, node3.lon)
      c = calculate_distance_meters(node1.lat, node1.lon, node3.lat, node3.lon)

      radians = Math.acos(((a**2) + (b**2) - (c**2)) / (2 * a * b))
      degrees = radians * 180 / Math::PI
      cross_product = cross_product(
        node2.lat - node1.lat,
        node2.lon - node1.lon,
        node3.lat - node1.lat,
        node3.lon - node1.lon
      )
      degrees += 180 if cross_product >= 0

      if degrees <= 85
        TurnDescription.sharp_left
      elsif degrees <= 170
        TurnDescription.left
      elsif degrees <= 190
        TurnDescription.straight
      elsif degrees <= 275
        TurnDescription.right
      else
        TurnDescription.sharp_right
      end
    end

    def cross_product(lat1, lat2, lon1, lon2)
      (lat1 * lon2) - (lat2 * lon1)
    end

    def nodes_with_named_ways
      return @nodes_with_named_ways if @nodes_with_named_ways

      node_ids = Set.new

      @osm_hierarchy.ways.each do |way|
        next unless way.name

        node_ids += way.node_ids
      end

      @nodes_with_named_ways = nodes_by_id.values_at(*node_ids.to_a)
    end

    def nodes_by_id
      @nodes_by_id ||= @osm_hierarchy.nodes.to_h { |node| [node.id, node] }
    end

    def ways_by_id
      @ways_by_id ||= @osm_hierarchy.ways.to_h { |way| [way.id, way] }
    end

    def ways_by_node_id
      return @ways_by_node_id if @ways_by_node_id

      hash = {}

      @osm_hierarchy.ways.each do |way|
        way.node_ids.each do |node_id|
          hash[node_id] ||= []

          hash[node_id] << way
        end
      end

      @ways_by_node_id = hash
    end
  end
end
