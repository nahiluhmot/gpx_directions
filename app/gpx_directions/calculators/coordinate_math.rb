module GpxDirections
  module Calculators
    # Math for GPS coordinates.
    module CoordinateMath
      EARTH_RADIUS_METERS = 6_378_000
      ONE_DEGREE_RADIANS = Math::PI / 180

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

      def calculate_turn_degrees(node1, node2, node3)
        return 180 if [node1, node2, node3].uniq.length != 3

        a = calculate_distance_meters(node1.lat, node1.lon, node2.lat, node2.lon)
        b = calculate_distance_meters(node2.lat, node2.lon, node3.lat, node3.lon)
        c = calculate_distance_meters(node1.lat, node1.lon, node3.lat, node3.lon)

        acos_arg = ((a**2) + (b**2) - (c**2)) / (2 * a * b)
        acos_arg = -1 if acos_arg < -1
        acos_arg = 1 if acos_arg > 1

        radians = Math.acos(acos_arg)
        degrees = radians * 180 / Math::PI

        cross_product = calculate_cross_product(
          node2.lat - node1.lat,
          node2.lon - node1.lon,
          node3.lat - node1.lat,
          node3.lon - node1.lon
        )

        degrees += 180 if cross_product >= 0

        degrees
      end

      def calculate_cross_product(lat1, lat2, lon1, lon2)
        (lat1 * lon2) - (lat2 * lon1)
      end
    end
  end
end
