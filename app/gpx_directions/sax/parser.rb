module GpxDirections
  module Sax
    # Define classes and hierarchy for a SAX parser using a Hash.
    class Parser < Module
      private_class_method :new

      class << self
        def define(config_by_element_type)
          classes_by_type = define_xml_classes(config_by_element_type)

          define_parser(classes_by_type)
        end

        private

        def define_parser(classes_by_type)
          new do
            const_set(:CLASSES_BY_TYPE, classes_by_type.freeze)

            classes_by_type.each do |type, klass|
              const_set(type.capitalize, klass)
            end

            define_singleton_method(:parse) do |io|
              parser = GenericParser.new(classes_by_type)

              Ox.sax_parse(parser, io)

              parser.result
            end
          end
        end

        def define_xml_classes(config_by_element_type)
          config_by_element_type.transform_values do |config|
            define_xml_class(**config)
          end
        end

        def define_xml_class(attrs: [], children: [])
          Struct.new(*attrs, *children) do
            const_set(:ATTRS, attrs.freeze)
            const_set(:CHILDREN, children.freeze)

            define_method(:attr?, &attrs.method(:include?))
            define_method(:child?, &children.method(:include?))
          end
        end
      end
    end
  end
end
