class Ribbon::Plugins
  class AroundStack
    attr_reader :subject

    def initialize(subject)
      @subject = subject.to_sym
      @_stack = []
    end

    def push(&block)
      raise Errors::Error, "Must pass block" unless block_given?

      AroundWrapper.new(subject, &block).tap { |wrapper|
        @_stack.push(wrapper)
      }
    end

    def call(*args, &block)
      raise Errors::Error, "Must pass block" unless block_given?
      call_stack = @_stack.dup

      inner_most = WrappedBlock.new(&block)
      call_stack.unshift(inner_most)

      outer_most = call_stack.pop
      outer_most.call(call_stack, *args)
    end

    class AroundWrapper
      attr_reader :subject, :block

      def initialize(subject, &block)
        @subject = subject
        @block = block
      end

      def call(call_stack, *args)
        wrapped = call_stack.pop
        raise Errors::Error, 'call stack too short' unless wrapped

        define_singleton_method("perform_#{subject}") { |*new_args|
          args = new_args unless new_args.empty?
          wrapped.call(call_stack, *args)
        }

        instance_exec(*args, &block)
      end
    end

    class WrappedBlock
      attr_reader :block

      def initialize(&block)
        @block = block
      end

      def call(call_stack, *args)
        raise Errors::Error, 'receiving non-empty call stack' unless call_stack.empty?
        block.call(*args)
      end
    end
  end # AroundStack
end # Ribbon::Plugins