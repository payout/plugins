class Plugins
  class AroundStack
    attr_reader :subject
    attr_accessor :scope

    def initialize(subject, scope=nil)
      @subject = subject.to_sym
      @scope = scope
      @_stack = []
    end

    def push(&block)
      raise Errors::Error, "Must pass block" unless block_given?

      AroundWrapper.new(self, subject, &block).tap { |wrapper|
        @_stack.push(wrapper)
      }
    end

    def dup
      AroundStack.new(subject, scope).tap { |stack|
        @_stack.each { |wrapper|
          stack.push(&wrapper.block)
        }
      }
    end

    def call(*args, &block)
      raise Errors::Error, "Must pass block" unless block_given?
      call_stack = @_stack.dup

      inner_most = WrappedBlock.new(&block)
      call_stack.unshift(inner_most)

      outer_most = call_stack.pop
      outer_most.call(call_stack, *args)

      # This shouldn't happen unless the AroundStack isn't functioning properly.
      raise Errors::Error, "Block passed was not called!" unless inner_most.called?

      inner_most.retval
    end

    class AroundWrapper
      attr_reader :stack, :subject, :block

      def initialize(stack, subject, &block)
        @stack = stack
        @subject = subject
        @block = block
      end

      def scope
        stack.scope
      end

      def method_missing(meth, *args, &block)
        super unless scope
        scope.send(meth, *args, &block)
      end

      def call(call_stack, *args)
        wrapped = call_stack.pop
        raise Errors::Error, 'call stack too short' unless wrapped

        define_singleton_method("perform_#{subject}") { |*new_args|
          args = new_args unless new_args.empty?
          wrapped.call(call_stack, *args)
        }

        singleton_class.instance_exec(subject) { |subject|
          alias_method subject, "perform_#{subject}"

          # Don't allow these to be overriden
          attr_reader :stack, :subject, :block
        }

        instance_exec(*args, &block)
      end
    end

    class WrappedBlock
      attr_reader :block
      attr_reader :retval

      def initialize(&block)
        @block = block
      end

      def called?
        !!@_called
      end

      ##
      # Call the wrapped block, ignoring the scope and call_stack arguments.
      def call(call_stack, *args)
        raise Errors::Error, 'receiving non-empty call stack' unless call_stack.empty?
        block.call(*args).tap { |retval|
          @retval = retval
          @_called = true
        }
      end
    end
  end # AroundStack
end # Plugins
