module GpxDirections
  # Generalized SAX Parser (using a DSL-defined hierarchy).
  class SaxParser < Ox::Sax
    def initialize(dsl_module)
      @dsl_module = dsl_module
      @element_stack = [dsl_module::Root.new]
      @skip_element = nil
    end

    def result
      @element_stack.first
    end

    def start_element(name)
      return if @skip_element

      if @element_stack.last.child?(name)
        @element_stack << @dsl_module::CLASSES_BY_TYPE[name].new
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
