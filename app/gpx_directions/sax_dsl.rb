module GpxDirections
  # Define classes and hierarchy for a SAX parser using a Hash.
  class SaxDSL < Module
    private_class_method :new

    def self.define(config_by_element_type)
      classes_by_type = {}

      config_by_element_type.each do |type, config|
        attrs, children = config.values_at(:attrs, :children)

        classes_by_type[type] = Struct.new(*attrs, *children) do
          const_set(:ATTRS, (attrs || []).freeze)
          const_set(:CHILDREN, (children || []).freeze)

          define_method(:attr?) { |name| self.class::ATTRS.include?(name) }
          define_method(:child?) { |name| self.class::CHILDREN.include?(name) }
        end
      end

      new do
        const_set(:CLASSES_BY_TYPE, classes_by_type.freeze)

        classes_by_type.each do |type, klass|
          const_set(type.capitalize, klass)
        end

        define_singleton_method(:parse) do |io|
          parser = SaxParser.new(self)

          Ox.sax_parse(parser, io)

          parser.result
        end
      end
    end
  end
end
