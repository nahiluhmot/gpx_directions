module GpxDirections
  # Parses OpenStreetMap files.
  OsmParser = SaxDSL.define(
    root: {
      children: [:osm]
    },
    osm: {
      children: [:bounds, :node, :way]
    },
    bounds: {
      attrs: [:minlat, :minlon, :maxlat, :maxlon]
    },
    node: {
      attrs: [:id, :lat, :lon]
    },
    way: {
      attrs: [:id],
      children: [:nd, :tag]
    },
    nd: {
      attrs: [:ref]
    },
    tag: {
      attrs: [:k, :v]
    }
  )
end
