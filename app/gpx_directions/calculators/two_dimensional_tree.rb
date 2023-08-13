module GpxDirections
  module Calculators
    # Stores Osm::Nodes in a tree format for fast lookup.
    class TwoDimensionalTree
      private_class_method :new

      def self.build(nodes)
        new.insert_nodes(nodes)
      end

      def initialize
        @nodes = {}
        @bounds_by_index = {
          0 => Bounds.new(
            min_lat: -Float::INFINITY,
            max_lat: Float::INFINITY,
            min_lon: -Float::INFINITY,
            max_lon: Float::INFINITY
          )
        }
      end

      def find_nearest_node(lat, lon)
        return if @nodes.empty?

        to_consider = [0]
        best_node = nil
        best_distance = Float::INFINITY

        until to_consider.empty?
          idx = to_consider.shift

          best_possible_distance = calculate_best_possible_distance(idx, lat, lon)
          next if best_distance < best_possible_distance

          node = @nodes[idx]
          distance = CoordinateMath.calculate_distance_score(node.lat, node.lon, lat, lon)

          if distance < best_distance
            best_node = node
            best_distance = distance
          end

          if consider_lat?(idx) ? (lat <= node.lat) : (lat <= node.lon)
            to_consider << left(idx)
            to_consider << right(idx)
          else
            to_consider << right(idx)
            to_consider << left(idx)
          end
        end

        best_node
      end

      def insert(node_to_insert)
        idx = 0
        consider_lat = true

        while (node_in_tree = @nodes[idx])
          go_left =
            consider_lat ?
              (node_to_insert.lat <= node_in_tree.lat) :
              (node_to_insert.lon <= node_in_tree.lon)

          idx = go_left ? left(idx) : right(idx)
          consider_lat = !consider_lat
        end

        @nodes[idx] = node_to_insert
        calculate_lat_lon_bounds(idx)

        self
      end

      def insert_nodes(nodes)
        return self if nodes.empty?

        nodes = nodes.dup
        to_insert = [[0, nodes.length - 1, true]]

        until to_insert.empty?
          start_idx, end_idx, consider_lat = to_insert.pop

          next if start_idx > end_idx

          comparator = consider_lat ? :lat : :lon
          idx = (start_idx + end_idx) / 2
          Sorting.quick_select!(nodes, start_idx, end_idx, idx, &comparator)

          median = nodes[idx]
          insert(median)

          to_insert << [start_idx, idx - 1, !consider_lat]
          to_insert << [idx + 1, end_idx, !consider_lat]
        end

        self
      end

      private

      def calculate_best_possible_distance(idx, lat, lon)
        bounds = @bounds_by_index[idx]

        return Float::INFINITY unless bounds

        best_possible_lat = lat.clamp(bounds.min_lat, bounds.max_lat)
        best_possible_lon = lon.clamp(bounds.min_lon, bounds.max_lon)

        CoordinateMath.calculate_distance_score(
          best_possible_lat,
          best_possible_lon,
          lat,
          lon
        )
      end

      def calculate_lat_lon_bounds(child_idx)
        return @bounds_by_index[child_idx] if @bounds_by_index.key?(child_idx)

        parent_idx = up(child_idx)
        parent = @nodes[parent_idx]
        bounds = @bounds_by_index[parent_idx].dup

        if consider_lat?(parent_idx)
          if child_idx.odd?
            bounds.max_lat = bounds.max_lat.clamp(-Float::INFINITY, parent.lat)
          end

          if child_idx.even?
            bounds.min_lat = bounds.min_lat.clamp(parent.lat, Float::INFINITY)
          end
        elsif child_idx.odd?
          bounds.max_lon = bounds.max_lon.clamp(-Float::INFINITY, parent.lon)
        elsif child_idx.even?
          bounds.min_lon = bounds.min_lon.clamp(parent.lon, Float::INFINITY)
        end

        @bounds_by_index[child_idx] = bounds
      end

      def consider_lat?(idx)
        Math.log2(idx + 1).floor.even?
      end

      def up(idx)
        (idx - 1) / 2
      end

      def left(idx)
        (2 * idx) + 1
      end

      def right(idx)
        (2 * idx) + 2
      end
    end
  end
end
