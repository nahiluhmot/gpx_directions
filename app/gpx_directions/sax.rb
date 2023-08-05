require "gpx_directions/sax/parser"
require "gpx_directions/sax/generic_parser"

module GpxDirections
  # Data structures, helper functions, and service objects related to
  # SAX XML parsers.
  module Sax
    module_function

    def define_parser(*args)
      Parser.define(*args)
    end
  end
end
