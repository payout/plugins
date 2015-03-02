class Ribbon::Plugins
  class BlockStack
    def initialize
      @_stack = []
    end

    def push(&block)
      @_stack.push(block)
    end

    def call(*args)
      @_stack.reverse_each { |block| block.call(*args) }
    end
  end
end