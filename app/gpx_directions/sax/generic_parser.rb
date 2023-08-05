module GpxDirections
  module Sax
    # Generalized SAX Parser (using a DSL-defined hierarchy).
    class GenericParser < Ox::Sax
      def initialize(classes_by_type)
        @classes_by_type = classes_by_type
        @element_stack = [classes_by_type[:root].new]
        @skip_element = nil
      end

      def result
        @element_stack.first
      end

      def start_element(name)
        return if @skip_element

        if @element_stack.last.child?(name)
          @element_stack << @classes_by_type[name].new
        else
          @skip_element = name
        end
      end

      def end_element(name)
        if @skip_element
          # TODO: count the number of skips for skips-within-skips.
          @skip_element = nil if name == @skip_element
        else
          old_tail = @element_stack.pop
          new_tail = @element_stack.last

          new_tail[name] ||= []
          new_tail[name] << old_tail
        end
      end

      def attr(name, value)
        return if @skip_element

        tail = @element_stack.last

        tail[name] = value if tail.attr?(name)
      end
    end
  end
end
