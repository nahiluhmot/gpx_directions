module GpxDirections
  GpxHierarchy = Struct.new(:points, keyword_init: true) do
    Point = Struct.new(:lat, :lon, keyword_init: true)

    def self.build(parse_root)
      new(
        points: parse_root.gpx.first.rte.first.rtept.map do |parse_rtept|
          Point.new(
            lat: BigDecimal(parse_rtept.lat),
            lon: BigDecimal(parse_rtept.lon)
          )
        end
      )
    end
  end
end
