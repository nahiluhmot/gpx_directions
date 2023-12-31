module GpxDirections
  # Data structures, helper functions, and service objects related to
  # .gpx files generated by OnTheGoMap.
  module Gpx
    # Parses .gpx files downloaded from OnTheGoMap.
    Parser = Sax.define_parser(
      root: {
        children: [:gpx]
      },
      gpx: {
        children: [:rte]
      },
      rte: {
        children: [:rtept]
      },
      rtept: {
        attrs: [:lat, :lon]
      }
    )

    # A Route is a sequence of Points.
    Route = Struct.new(:points, keyword_init: true)

    # A Point is a GPS coordinate.
    Point = Struct.new(:lat, :lon, keyword_init: true)

    module_function

    # Parsers

    def parse_xml(io)
      Parser.parse(io)
    end

    # Builders

    def build_route(parse_root)
      points = parse_root
        .gpx
        .first
        .rte
        .first
        .rtept
        .map(&method(:build_point))

      Route.new(points:)
    end

    def build_point(parse_rtept)
      lat = BigDecimal(parse_rtept.lat)
      lon = BigDecimal(parse_rtept.lon)

      Point.new(lat:, lon:)
    end
  end
end
