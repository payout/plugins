require 'ribbon/plugins/version'

module Ribbon
  class Plugins
    autoload(:Errors,      'ribbon/plugins/errors')
    autoload(:Plugin,      'ribbon/plugins/plugin')
    autoload(:AroundStack, 'ribbon/plugins/around_stack')
    autoload(:BlockStack,  'ribbon/plugins/block_stack')

    attr_reader :component

    def initialize(component=nil, &block)
      @component = component
      @_plugin_loader = block
    end

    def add(plugin=nil, &block)
      plugin = _load(plugin, &block)
      _add_plugin(plugin.new(self))
    end

    def clear
      @_plugins = []
      nil
    end

    def before(subject, *args)
      _plugins.reverse_each { |plugin| plugin.before(subject, *args) }
    end

    def after(subject, *args)
      _plugins.reverse_each { |plugin| plugin.after(subject, *args) }
    end

    def around(subject, *args, &block)
      _around_stack.call(subject, *args) { |subject, *args| block.call(*args) }
    end

    def perform(subject, *args, &block)
      before(subject, *args)
      around(subject, *args, &block)
      after(subject, *args)
    end

    private
    def _plugins
      @_plugins ||= []
    end

    def _around_stack
      @__around_stack ||= AroundStack.new(:block)
    end

    def _add_plugin(plugin)
      _plugins.push(plugin)

      _around_stack.push { |subject, *args|
        plugin.around(subject, *args) {
          perform_block
        }
      }

      plugin
    end

    def _load(plugin, &block)
      if plugin
        _load_plugin(plugin)
      elsif block_given?
        Plugin.create(&block)
      else
        raise Errors::LoadError, 'No plugin information provided'
      end
    end

    def _load_plugin(plugin)
      _plugin_loader(plugin).tap { |p| plugin = p if p }

      case plugin
      when Class
        plugin < Plugin && plugin or
          raise Errors::LoadError, "Invalid plugin class: #{plugin.inspect} Must extend Plugin."
      when Proc
        Plugin.create(&plugin)
      else
        raise Errors::LoadError, "Invalid plugin identifier: #{plugin.inspect}"
      end
    end

    def _plugin_loader(plugin)
      @_plugin_loader && @_plugin_loader.call(plugin)
    end
  end # Plugins
end # Ribbon
