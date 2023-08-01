module GpxDirections
  # Parses OpenStreetMap files.
  OsmParser = SaxDSL.define(
    root: {
      children: [:osm]
    },
    osm: {
      children: [:bounds, :node, :way, :relation]
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
    relation: {
      attrs: [:id],
      children: [:member, :tag]
    },
    nd: {
      attrs: [:ref]
    },
    member: {
      attrs: [:type, :ref, :role]
    },
    tag: {
      attrs: [:k, :v]
    }
  )
end
