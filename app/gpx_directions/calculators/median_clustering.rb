module GpxDirections
  module Calculators
    # Clusters by median lat, then median lon, then median lat...
    module MedianClustering
      ClusterSet = Struct.new(:clusters, keyword_init: true)
      Cluster = Struct.new(:bounds, keyword_init: true)

      module_function

      def calculate_clusters(points, max_cluster_area_km2: BigDecimal("0.05"))
        points = points.dup
        to_consider = [[0, points.length.pred, true]]

        bounds_ary = []

        until to_consider.empty?
          start_idx, end_idx, consider_lat = to_consider.pop

          next if start_idx > end_idx

          bounds = calculate_bounds(points, start_idx, end_idx)

          if CoordinateMath.calculate_area_km2(bounds) <= max_cluster_area_km2
            bounds_ary << bounds

            next
          end

          comparator = consider_lat ? :lat : :lon
          median_idx = (start_idx + end_idx) / 2

          Sorting.quick_select!(points, start_idx, end_idx, median_idx, &comparator)

          to_consider << [start_idx, median_idx, !consider_lat]
          to_consider << [median_idx + 1, end_idx, !consider_lat]
        end

        bounds_ary
      end

      def calculate_bounds(points, start_idx, end_idx)
        bounds = Bounds.new(
          min_lat: Float::INFINITY,
          max_lat: -Float::INFINITY,
          min_lon: Float::INFINITY,
          max_lon: -Float::INFINITY
        )

        (start_idx..end_idx).each do |idx|
          point = points[idx]
          lat = point.lat
          lon = point.lon

          bounds.min_lat = lat if bounds.min_lat > lat
          bounds.max_lat = lat if bounds.max_lat < lat
          bounds.min_lon = lon if bounds.min_lon > lon
          bounds.max_lon = lon if bounds.max_lon < lon
        end

        bounds
      end
    end
  end
end
