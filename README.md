[![Gem Version](https://badge.fury.io/rb/ribbon-plugins.svg)](http://badge.fury.io/rb/ribbon-plugins) [![Code Climate](https://codeclimate.com/github/ribbon/plugins/badges/gpa.svg)](https://codeclimate.com/github/ribbon/plugins) [![Test Coverage](https://codeclimate.com/github/ribbon/plugins/badges/coverage.svg)](https://codeclimate.com/github/ribbon/plugins)

# Plugins

Easily add plugins to any library. Plugins takes care of calling before, after
and around callbacks for you. All you need to do is wrap your blocks of interest
in a `Plugins#perform` block. Add any number of plugins and any number of callbacks
within each plugin.

## Installation

Add this to your Gemfile:

```
gem 'ribbon-plugins'
```

Then run

```
bundle
```

Or you can install it manually:

```
gem install ribbon-plugins
```

## Basic Usage

### Define your component
In Plugins, whatever code you're writing that will have plugin support is called a "component". The `Ribbon::Plugins::ComponentMixin` simplifies integrating with the Plugins gem, although it's not required that you use it.

```ruby
require 'ribbon/plugins'
class ComponentWithPlugins
  include Ribbon::Plugins::ComponentMixin

  ##
  # Allow users to use the :logging symbol to reference the LoggingPlugin
  plugin_loader { |plugin|
    case plugin
    when :logging
      LoggingPlugin
    end
  }

  def do_something(*args)
    plugins.perform(:do_something, *args) { |*args|
      puts "Doing something: #{args.inspect}"
    }
  end
end
```

### Define your plugins

```ruby
class LoggingPlugin < Ribbon::Plugins::Plugin
  def initialize(plugins, file_name=nil)
    super(plugins)
    raise "Logging to a file is't supported yet!" if file_name
  end

  before_do_something do |*args|
    # Any instance methods can be called within callback blocks.
    log("Sending these args: #{args.inspect}")
  end

  around_do_something do |*args|
    begin
      do_something # Magic method to call code being performed
    rescue Exception => e
      log("Exception occurred! #{e.inspect}")
    end
  end

  after_do_something do |*args|
    log("Finished with args: #{args.inspect}")
  end

  private
  def log(message)
    puts "Logging Message: #{message}"
  end
end
```

### Add plugins to your component

```ruby
component = ComponentWithPlugins.new
component.plugin(:logging) # Utilizes your plugin_loader block.

# This would also work, too.
# But don't both because plugins can be added multiple times!
# component.plugin(LoggingPlugin)

# Alternatively, pass additional args to the Plugin initializer:
# component.plugin(:logging, 'file_name') # LoggingPlugin will raise an exception

component.do_something(1, :two, 'three')
# Should output:
# Logging Message: Sending these args: [1, :two, "three"]
# Doing something: [1, :two, "three"]
# Logging Message: Finished with args: [1, :two, "three"]
```
User's can also define their own custom plugins:
```ruby
component.plugin {
  after_do_something {
    puts "Custom plugin!"
  }
}

component.do_something("hello world")
# Should output:
# Logging Message: Sending these args: ["hello world"]
# Doing something: ["hello world"]
# Custom plugin!
# Logging Message: Finished with args: ["hello world"]
```

## Details

### Defining a Plugin

There are two ways to define a plugin.
  1. Extending `Plugins::Plugin`
  2. `Plugins::Plugin.create`

When defining a plugin, you can define any arbitrary before, around and after callbacks.
You can also define multiple callbacks of the same type. They will be executed in reverse order
that you defined them.

#### Extending `Plugins::Plugin`

```ruby
require 'ribbon/plugins'

class CustomPlugin < Ribbon::Plugins::Plugin
  before_i_do_something do |*args|
    puts "I'm about to do something..."
  end
  before_i_do_something { puts "This one will be executed first" }

  around_i_do_something do |*args|
    puts "And you won't like it..."

    perform_i_do_something # Just `i_do_something` will also work.

    puts "But too bad..."
  end

  after_i_do_something do |*args|
    puts "Because I just did it."
    helper_method
  end

  # All *instance* methods will be available.
  def helper_method
    puts "Running helper method"
  end
end
```

#### Plugin.create

You can also create on-the-fly plugins:

```ruby
custom_plugin = Ribbon::Plugins::Plugin.create do
  before_brush_teeth do
    floss
  end

  after_brush_teeth do
    spit
  end
end
```
