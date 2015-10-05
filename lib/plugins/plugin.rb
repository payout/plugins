class Plugins
  class Plugin
    class << self
      def create(&block)
        Class.new(Plugin).tap { |k| k.class_eval(&block) if block }
      end

      def method_missing(meth, *args, &block)
        if /^(before|after|around)_(\w+)$/.match(meth.to_s)
          _define_callback($1, $2, &block)
        else
          super
        end
      end

      def _define_callback(type, subject, &block)
        _callbacks(type, subject).push(&block)
      end

      def _callbacks(type, subject)
        ((@__callbacks ||= {})[type.to_sym] ||= {})[subject.to_sym] ||= _empty_stack_for(type, subject)
      end

      def _empty_stack_for(type, subject)
        case type.to_sym
        when :before, :after
          BlockStack.new
        when :around
          AroundStack.new(subject)
        else
          raise Errors::Error, "Invalid type: #{type}"
        end
      end
    end

    attr_reader :plugins

    def initialize(plugins=nil)
      @plugins = plugins
    end

    def before(subject, *args)
      _callbacks(:before, subject).call(*args)
    end

    def after(subject, *args)
      _callbacks(:after, subject).call(*args)
    end

    def around(subject, *args, &block)
      _callbacks(:around, subject).call(*args, &block)
    end

    private
    def _callbacks(type, subject)
      ((@_callbacks ||= {})[type.to_sym] ||= {})[subject.to_sym] ||=
        self.class._callbacks(type, subject).dup.tap { |stack|
          stack.scope = self
        }
    end
  end # Plugin
end # Plugins
