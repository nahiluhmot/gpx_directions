module GpxDirections
  module Calculators
    # Math for GPS coordinates.
    module CoordinateMath
      PI = BigMath::PI(10)
      EARTH_CIRCUMFRENCE = BigDecimal("40075000")
      EARTH_RADIUS_METERS = EARTH_CIRCUMFRENCE / (2 * PI)
      ONE_DEGREE_RADIANS = PI / 180

      METERS_PER_DEGREE_LATITUDE = EARTH_CIRCUMFRENCE / 360
      DEGREES_LATITUDE_PER_METER = 1 / METERS_PER_DEGREE_LATITUDE

      module_function

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

      # Calculate an approximate distance score (faster, no sqrt or trig).
      def calculate_distance_score(lat1, lon1, lat2, lon2)
        ((lat1 - lat2)**2) + ((lon1 - lon2)**2)
      end

      def calculate_bounds_around_point(point, padding_meters)
        meters_per_degree_longitude = METERS_PER_DEGREE_LATITUDE * Math.cos(point.lat * ONE_DEGREE_RADIANS)

        delta_meters = padding_meters / 2
        delta_lat = delta_meters * DEGREES_LATITUDE_PER_METER
        delta_lon = delta_meters / meters_per_degree_longitude

        Bounds.new(
          min_lat: point.lat - delta_lat,
          max_lat: point.lat + delta_lat,
          min_lon: point.lon - delta_lon,
          max_lon: point.lon + delta_lon
        )
      end

      def calculate_turn_degrees(node1, node2, node3)
        return 180 if [node1, node2, node3].uniq.length != 3

        a = calculate_distance_meters(node1.lat, node1.lon, node2.lat, node2.lon)
        b = calculate_distance_meters(node2.lat, node2.lon, node3.lat, node3.lon)
        c = calculate_distance_meters(node1.lat, node1.lon, node3.lat, node3.lon)

        acos_arg = ((a**2) + (b**2) - (c**2)) / (2 * a * b)

        radians = Math.acos(acos_arg.clamp(-1, 1))
        degrees = radians * 180 / Math::PI

        cross_product = calculate_cross_product(
          node2.lat - node1.lat,
          node2.lon - node1.lon,
          node3.lat - node1.lat,
          node3.lon - node1.lon
        )

        degrees += 180 if cross_product >= 0

        BigDecimal(degrees, 16)
      end

      def calculate_cross_product(lat1, lat2, lon1, lon2)
        (lat1 * lon2) - (lat2 * lon1)
      end
    end
  end
end
