module GpxDirections
  module Calculators
    module MedianPartitioning
      module_function

      def calculate_partition_bounds(points, max_area_km2)
        partitions = []
        to_partition = [[0, points.length - 1, true]]

        points = points.dup

        while to_partition.any?
          start_idx, end_idx, consider_lat = to_partition.shift

          next if start_idx > end_idx

          bounds = calculate_bounds(points, start_idx, end_idx)
          bounds_area = CoordinateMath.calculate_area_km2(bounds.min_lat, bounds.min_lon, bounds.max_lat, bounds.max_lon)

          if bounds_area <= max_area_km2
            partitions << bounds

            next
          end

          comparator = consider_lat ? :lat : :lon
          len = (end_idx - start_idx) + 1
          mean = (start_idx..end_idx)
            .sum { |idx| points[idx].public_send(comparator) }
            .then { |sum| sum / len }
          pivot_idx = Sorting.partition_by_value!(points, start_idx, end_idx, mean, &comparator)

          to_partition << [start_idx, pivot_idx, !consider_lat]
          to_partition << [pivot_idx + 1, end_idx, !consider_lat]
        end

        partitions
      end

      def calculate_bounds(nodes, start_idx, end_idx)
        (start_idx..end_idx).each_with_object(Bounds.new) do |idx, bounds|
          node = nodes[idx]
          lat = node.lat
          lon = node.lon

          bounds.min_lat = lat if bounds.min_lat.nil? || (bounds.min_lat > lat)
          bounds.max_lat = lat if bounds.max_lat.nil? || (bounds.max_lat < lat)
          bounds.min_lon = lon if bounds.min_lon.nil? || (bounds.min_lon > lon)
          bounds.max_lon = lon if bounds.max_lon.nil? || (bounds.max_lon < lon)
        end
      end
    end
  end
end
