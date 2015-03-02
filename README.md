[![Gem Version](https://badge.fury.io/rb/ribbon-plugins.svg)](http://badge.fury.io/rb/ribbon-plugins) [![Code Climate](https://codeclimate.com/github/ribbon/plugins/badges/gpa.svg)](https://codeclimate.com/github/ribbon/plugins)

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

```ruby
custom_plugin = Plugins::Plugin.create do
  before_save do
    puts "Saving..."
  end

  around_save do
    # Let's catch any exceptions
    begin
      preform_save # Magic method created just for you.
    rescue Exception => e
      puts "Oops! This happened: #{e.inspect}"
    end
  end

  after_save do
    puts "Saved!"
  end
end

plugins = Plugins.new
plugins.add(custom_plugin)
plugins.perform(:save) do
  save!
end
```

## Defining a Plugin

There are two ways to define a plugin.
  1. Extending `Plugins::Plugin`
  2. `Plugins::Plugin.create`

### Extending `Plugins::Plugin`

```ruby
require 'ribbon/plugins'

class CustomPlugin < Ribbon::Plugins::Plugin
  before_i_do_something do |*args|
    puts "I'm about to do something..."
  end

  around_i_do_something do |*args|
    puts "And you won't like it..."
    perform_i_do_something
    puts "But too bad..."
  end

  after_i_do_something do |*args|
    puts "Because I just did it."
  end
end
```

You can define any arbitrary before, around and after callbacks. You can also
define multiple callbacks of the same type. They will be executed in reverse order
that you defined them.

### Plugin.create

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
