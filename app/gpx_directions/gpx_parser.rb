module GpxDirections
  GpxParser = SaxDSL.define(
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
end
