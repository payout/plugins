require 'plugins/version'

class Plugins
  autoload(:Errors,         'plugins/errors')
  autoload(:Plugin,         'plugins/plugin')
  autoload(:AroundStack,    'plugins/around_stack')
  autoload(:BlockStack,     'plugins/block_stack')
  autoload(:ComponentMixin, 'plugins/component_mixin')

  attr_reader :component, :plugin_loader

  def initialize(component=nil, &block)
    @component = component
    @plugin_loader = block
  end

  def add(plugin=nil, *args, &block)
    plugin = _load(plugin, &block)
    _add_plugin(plugin.new(self, *args))
  end

  def clear
    @_plugins = nil
    @_around_stack = nil
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
    retval = around(subject, *args, &block)
    after(subject, *args)

    retval
  end

  private
  def _plugins
    @_plugins ||= []
  end

  def _around_stack
    @_around_stack ||= AroundStack.new(:block, self)
  end

  def _add_plugin(plugin)
    _plugins.push(plugin)

    _around_stack.push { |subject, *args|
      plugin.around(subject, *args) { |*args|
        perform_block(subject, *args)
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
    _call_plugin_loader(plugin).tap { |p| plugin = p if p }

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

  def _call_plugin_loader(plugin)
    plugin_loader && component.instance_exec(plugin, &plugin_loader)
  end
end # Plugins
