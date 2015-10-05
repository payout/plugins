class Plugins
  class BlockStack
    attr_accessor :scope

    def initialize(scope=nil)
      @scope = scope
      @_stack = []
    end

    def dup
      BlockStack.new.tap { |stack|
        @_stack.each { |block| stack.push(&block) }
      }
    end

    def push(&block)
      @_stack.push(block)
    end

    def call(*args)
      @_stack.reverse_each { |block|
        if scope
          scope.instance_exec(*args, &block)
        else
          block.call(*args)
        end
      }
    end
  end
end
