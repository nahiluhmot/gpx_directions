module GpxDirections
  module Calculators
    # Calculates K-means.
    class KMeans
      ClusterSet = Struct.new(:clusters, :points, :cluster_by_point, keyword_init: true)
      Cluster = Struct.new(:bounds, :centroid, keyword_init: true)

      def initialize(rng = method(:rand))
        @rng = rng
      end

      def k_means(k, points, max_iterations: 100)
        raise ArgumentError "Cannot calculate #{k} means for #{points.length} points" if k > points.length

        cluster_set = build_cluster_set(k, points)
        reposition_points(cluster_set)

        max_iterations.times do
          recalculate_centroids(cluster_set)

          break unless reposition_points(cluster_set)
        end

        calculate_bounds(cluster_set)

        cluster_set
      end

      private

      def build_cluster_set(k, points)
        clusters = []

        k.times do
          furthest_idx =
            if clusters.empty?
              @rng.call(points.length)
            else
              max_by_idx(points) do |point|
                clusters
                  .map do |cluster|
                    CoordinateMath.calculate_distance_score(
                      cluster.centroid.lat,
                      cluster.centroid.lon,
                      point.lat,
                      point.lon
                    )
                  end
                  .min
              end
            end

          clusters << Cluster.new(centroid: points[furthest_idx].dup)
        end

        cluster_by_point = points.each_with_index.each_with_object({}) { |(_, p_idx), hash| hash[p_idx] = -1 }

        ClusterSet.new(clusters:, points:, cluster_by_point:)
      end

      def recalculate_centroids(cluster_set)
        return if cluster_set.points.empty?

        cluster_count = cluster_set.clusters.length
        lat_sum_by_cluster = Array.new(cluster_count, 0)
        lon_sum_by_cluster = Array.new(cluster_count, 0)
        count_by_cluster = Array.new(cluster_count, 0)

        cluster_set.cluster_by_point.each do |p_idx, c_idx|
          point = cluster_set.points[p_idx]

          lat_sum_by_cluster[c_idx] += point.lat
          lon_sum_by_cluster[c_idx] += point.lon
          count_by_cluster[c_idx] += 1
        end

        cluster_set.clusters.each_with_index do |cluster, idx|
          count = count_by_cluster[idx]

          next if count.zero?

          cluster.centroid.lat = lat_sum_by_cluster[idx] / count
          cluster.centroid.lon = lon_sum_by_cluster[idx] / count
        end
      end

      def reposition_points(cluster_set)
        updated = false

        cluster_set.cluster_by_point.each do |p_idx, c_idx|
          point = cluster_set.points[p_idx]

          updated_c_idx = min_by_idx(cluster_set.clusters) do |cluster|
            CoordinateMath.calculate_distance_score(
              cluster.centroid.lat,
              cluster.centroid.lon,
              point.lat,
              point.lon
            )
          end

          if c_idx != updated_c_idx
            cluster_set.cluster_by_point[p_idx] = updated_c_idx

            updated = true
          end
        end

        updated
      end

      def calculate_bounds(cluster_set)
        cluster_set.clusters.each do |cluster|
          cluster.bounds = Bounds.new(
            min_lat: Float::INFINITY,
            max_lat: -Float::INFINITY,
            min_lon: Float::INFINITY,
            max_lon: -Float::INFINITY
          )
        end

        cluster_set.cluster_by_point.each do |p_idx, c_idx|
          point = cluster_set.points[p_idx]
          cluster = cluster_set.clusters[c_idx]

          cluster.bounds.min_lat = point.lat if cluster.bounds.min_lat > point.lat
          cluster.bounds.max_lat = point.lat if cluster.bounds.max_lat < point.lat
          cluster.bounds.min_lon = point.lon if cluster.bounds.min_lon > point.lon
          cluster.bounds.max_lon = point.lon if cluster.bounds.max_lon < point.lon
        end
      end

      def max_by_idx(ary)
        max = -Float::INFINITY
        max_idx = -1

        ary.each_with_index do |ele, idx|
          val = yield(ele)

          if val > max
            max = val
            max_idx = idx
          end
        end

        max_idx
      end

      def min_by_idx(ary)
        min = Float::INFINITY
        min_idx = -1

        ary.each_with_index do |ele, idx|
          val = yield(ele)

          if val < min
            min = val
            min_idx = idx
          end
        end

        min_idx
      end
    end
  end
end
