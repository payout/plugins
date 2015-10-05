class Plugins
  ##
  # Intended to be mixed into any class utilizing the plugins functionality.
  module ComponentMixin
    def self.included(base)
      base.extend(ClassMethods)
    end

    module ClassMethods
      ##
      # Get or define the plugin loader.
      #
      # This block will be used to load a plugin given the value passed to the
      # +plugin+ instance method. It's the responsibility of this block to
      # translate the inputted value into either a Class that extends Plugin
      # or a Proc.
      #
      # If for a particular value you wish to not perform any translation,
      # return falsey.
      def plugin_loader(&block)
        if block_given?
          @_plugin_loader = block
        else
          @_plugin_loader
        end
      end
    end

    ###
    # Instance Methods
    ###

    ##
    # Reference to the Plugins instance for the component.
    def plugins
      @plugins ||= Plugins.new(self, &self.class.plugin_loader)
    end

    ##
    # Add a plugin.
    def plugin(*args, &block)
      plugins.add(*args, &block)
    end
  end
end
