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

        leaf_idx = find_matching_leaf_idx(lat, lon)
        to_consider = tree_ancestors(leaf_idx)
        already_considered = Set.new
        best_node = nil
        best_distance = Float::INFINITY

        until to_consider.empty?
          idx = to_consider.shift
          node = @nodes[idx]
          distance = CoordinateMath.calculate_distance_score(node.lat, node.lon, lat, lon)

          if distance < best_distance
            best_node = node
            best_distance = distance
          end

          [left(idx), right(idx)].each do |cidx|
            next if already_considered.member?(cidx)

            best_possible_distance = calculate_best_possible_distance(cidx, lat, lon)

            to_consider << cidx if best_possible_distance < best_distance
          end

          already_considered << node.id
        end

        best_node
      end

      def insert(node_to_insert)
        idx = 0

        while (node_in_tree = @nodes[idx])
          go_left =
            consider_lat?(idx) ?
              (node_in_tree.lat > node_to_insert.lat) :
              (node_in_tree.lon > node_to_insert.lon)

          idx = go_left ? left(idx) : right(idx)
        end

        @nodes[idx] = node_to_insert

        self
      end

      def insert_nodes(nodes)
        return self if nodes.empty?

        nodes = nodes.dup
        to_insert = [[0, nodes.length - 1, 0]]

        until to_insert.empty?
          start_idx, end_idx, level = to_insert.pop

          next if start_idx > end_idx

          comparator = level.even? ? :lat : :lon
          Sorting.in_place_sort_by!(nodes, start_idx, end_idx, &comparator)

          idx = (start_idx + end_idx) / 2
          median = nodes[idx]

          insert(median)

          to_insert << [start_idx, idx - 1, level + 1]
          to_insert << [idx + 1, end_idx, level + 1]
        end

        self
      end

      private

      def find_matching_leaf_idx(lat, lon)
        idx = 0

        loop do
          ridx = right(idx)
          lidx = left(idx)
          lnode = @nodes[lidx]
          rnode = @nodes[ridx]

          break if lnode.nil? && rnode.nil?

          idx =
            if lnode.nil?
              ridx
            elsif rnode.nil?
              lidx
            elsif consider_lat?(idx)
              if @nodes[idx].lat > lat
                ridx
              else
                lidx
              end
            elsif @nodes[idx].lon > lon
              ridx
            else
              lidx
            end
        end

        idx
      end

      def calculate_best_possible_distance(idx, lat, lon)
        return Float::INFINITY unless @nodes.key?(idx)

        bounds = calculate_lat_lon_bounds(idx)

        best_possible_lat = lat.clamp(bounds.min_lat, bounds.max_lat)
        best_possible_lon = lon.clamp(bounds.min_lon, bounds.max_lon)

        CoordinateMath.calculate_distance_score(
          best_possible_lat,
          best_possible_lon,
          lat,
          lon
        )
      end

      def calculate_lat_lon_bounds(idx)
        tree_ancestors(idx).reverse_each.each_cons(2) do |parent_idx, child_idx|
          next if @bounds_by_index.key?(child_idx)

          parent = @nodes[parent_idx]
          bounds = @bounds_by_index[parent_idx].dup
          @bounds_by_index[child_idx] = bounds

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
        end

        @bounds_by_index[idx]
      end

      def tree_ancestors(idx)
        ancestors = []
        ancestor_idx = idx

        loop do
          ancestors << ancestor_idx

          break if ancestor_idx.zero?

          ancestor_idx = up(ancestor_idx)
        end

        ancestors
      end

      def consider_lat?(idx)
        tree_level(idx).even?
      end

      def tree_level(idx)
        Math.log2(idx + 1).floor
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
