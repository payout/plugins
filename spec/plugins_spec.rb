module Ribbon
  RSpec.describe Plugins do
    let(:plugins) { Plugins.new }
    let(:empty_plugin) { Plugins::Plugin.create }
    let(:plugin) { empty_plugin }
    let(:args) { [1, :two, 'three'] }
    let(:block) { Proc.new { 'block retval' } }

    describe '#add' do
      subject { plugins.add(plugin) }

      context 'with valid plugin' do
        after { subject }
        it 'should pass plugins to plugin' do
          expect(plugin).to receive(:new).with(plugins).once
        end

        it 'should return plugin instance' do
          expect(subject).to be_a Plugins::Plugin
        end
      end # valid plugin

      context 'with proc' do
        subject { plugins.add(Proc.new {}) }

        it 'should return a plugin instance' do
          expect(subject).to be_a Plugins::Plugin
        end

        it 'should have reference to plugins' do
          expect(subject.plugins).to eq plugins
        end
      end # with proc

      context 'with block' do
        subject { plugins.add(&Proc.new {}) }

        it 'should return a plugin instance' do
          expect(subject).to be_a Plugins::Plugin
        end
      end # with block

      context 'with invalid plugin class' do
        let(:plugin) { Class.new }

        it 'should raise error' do
          expect { subject }.to raise_error(
            Plugins::Errors::LoadError,
            /^Invalid plugin class: #<Class:.*> Must extend Plugin.$/
          )
        end
      end # invalid plugin class

      context 'with string' do
        let(:plugin) { 'some string' }

        it 'should raise error' do
          expect { subject }.to raise_error(
            Plugins::Errors::LoadError, "Invalid plugin identifier: #{plugin.inspect}"
          )
        end

        context 'with load block returning plugin' do
          before { $empty_plugin = empty_plugin }
          let(:plugins) { Plugins.new { |p| $empty_plugin } }

          it 'should return plugin instance' do
            expect(subject).to be_an empty_plugin
          end
        end # with load block returning plugin

        context 'with load block returning nil' do
          let(:plugins) { Plugins.new { |p| nil } }

          it 'should raise error' do
            expect { subject }.to raise_error(
              Plugins::Errors::LoadError, "Invalid plugin identifier: #{plugin.inspect}"
            )
          end
        end # with load block returning nil

        context 'with load block returning invalid plugin' do
          let(:plugins) { Plugins.new { |p| Class.new } }

          it 'should raise error' do
            expect { subject }.to raise_error(
              Plugins::Errors::LoadError,
              /^Invalid plugin class: #<Class:.*> Must extend Plugin.$/
            )
          end
        end # with load block returning invalid plugin
      end # with string

      context 'with additional initialization args' do
        before do
          plugin.class_eval {
            def initialize(plugins, *args)
              super(plugins)
            end
          }
        end

        subject { plugins.add(plugin, 1, :two, 'three') }
        after { subject }
        it { expect(plugin).to receive(:new).with(plugins, 1, :two, 'three').once }
      end # with additional initialization args
    end # #add

    describe '#around' do
      # Need to use a separate call_counter because AroundStack doesn't call
      # the blocks, it runs instance_exec on itself instead.
      let(:call_counter) { double('call_counter') }
      before { allow(call_counter).to receive(:call) }

      # Make call_counter available to around_callback block
      before { $call_counter = call_counter }
      let(:around_callback) { Proc.new { |*args| $call_counter.call(*args); perform_subject; 'around_callback retval' } }
      before { $around_callback = around_callback }

      subject { plugins.around(:subject, *args, &block) }
      after { subject }

      context 'with no plugins' do
        it 'should run block' do
          expect(block).to receive(:call).with(*args).once
        end

        it 'should return block retval' do
          is_expected.to eq 'block retval'
        end
      end # with no plugins

      context 'with empty plugin' do
        before { plugins.add(plugin) }

        it 'should run block' do
          expect(block).to receive(:call).with(*args).once
        end

        it 'should return block retval' do
          is_expected.to eq 'block retval'
        end
      end # with empty plugin

      context 'with non-empty plugin' do
        let(:plugin) {
          Plugins::Plugin.create {
            around_subject(&$around_callback)
          }
        }

        before { plugins.add(plugin) }

        it 'should run block' do
          expect(block).to receive(:call).with(*args).once
        end

        it 'should run plugin around_callback' do
          expect(call_counter).to receive(:call).with(*args).once
        end

        it 'should return block retval' do
          is_expected.to eq 'block retval'
        end
      end # with non-empty plugin

      context 'with three plugins' do
        let(:plugin) {
          Plugins::Plugin.create {
            around_subject(&$around_callback)
          }
        }

        before { plugins.add(plugin); plugins.add(plugin); plugins.add(plugin) }

        it 'should run block' do
          expect(block).to receive(:call).with(*args).once
        end

        it 'should run plugin around_callback' do
          expect(call_counter).to receive(:call).with(*args).exactly(3).times
        end

        it 'should return block retval' do
          is_expected.to eq 'block retval'
        end
      end # with three plugins
    end # #around

    describe '#perform' do
      context 'with plugin with all around_callbacks' do
        let(:plugin) {
          Plugins::Plugin.create {
            before_subject { 'before retval' }
            around_subject { perform_subject; 'around_retval' }
            after_subject { 'after retval' }
          }
        }

        before { plugins.add(plugin) }
        subject { plugins.perform(:subject, *args, &block) }
        after { subject }

        it 'should call before' do
          expect(plugins).to receive(:before).with(:subject, *args, &block).once
        end

        it 'should call around' do
          expect(plugins).to receive(:around).with(:subject, *args, &block).once
        end

        it 'should call after' do
          expect(plugins).to receive(:after).with(:subject, *args, &block).once
        end

        it 'should return block retval' do
          is_expected.to eq 'block retval'
        end
      end # with plugin with all around_callbacks defined.

      context 'with plugin with incrementing arounds' do
        let(:block) { Proc.new { |count| count+1 } }
        let(:call_counter) { Proc.new {} }
        before { $call_counter = call_counter }
        let(:around_callback) { Proc.new { |count| $call_counter.call(count); perform_count(count+1) } }
        before { $around_callback = around_callback }
        let(:plugin) {
          Plugins::Plugin.create { around_count(&$around_callback) }
        }

        before { plugins.add(plugin); plugins.add(plugin); plugins.add(plugin) }
        subject { plugins.perform(:count, 1, &block) }
        after { subject }

        it 'should pass count down plugins' do
          expect(call_counter).to receive(:call).with(1).once
          expect(call_counter).to receive(:call).with(2).once
          expect(call_counter).to receive(:call).with(3).once
        end

        it 'should call block' do
          expect(block).to receive(:call).with(4)
        end

        it { is_expected.to eq 5 }
      end # with plugin with incrementing arounds

      context 'with plugin with instance method' do
        let(:plugin) {
          Plugins::Plugin.create {
            before_subject { |*args| a_method(:before, *args) }
            around_subject { |*args| a_method(:around, *args); perform_subject }
            after_subject { |*args| a_method(:after, *args) }

            def a_method(*args); end
          }
        }

        let(:plugin_instance) { plugins.add(plugin) }
        before { allow(plugin_instance).to receive(:a_method) }

        subject { plugins.perform(:subject, *args, &block) }
        after { subject }

        it 'should call instance method in before' do
          expect(plugin_instance).to receive(:a_method).with(:before, *args).once
        end

        it 'should call instance method in around' do
          expect(plugin_instance).to receive(:a_method).with(:around, *args).once
        end

        it 'should call instance method in after' do
          expect(plugin_instance).to receive(:a_method).with(:after, *args).once
        end

        it { is_expected.to eq 'block retval' }

        context 'with multiple instances of the same plugin' do
          # Check that multiple instances of the same plugin execute within
          # their own scope.
          let(:plugin_instance2) { plugins.add(plugin) }
          before { allow(plugin_instance2).to receive(:a_method) }

          it { expect(plugin_instance).to receive(:a_method).with(:before, *args).once }
          it { expect(plugin_instance).to receive(:a_method).with(:around, *args).once }
          it { expect(plugin_instance).to receive(:a_method).with(:after, *args).once }

          it { expect(plugin_instance2).to receive(:a_method).with(:before, *args).once }
          it { expect(plugin_instance2).to receive(:a_method).with(:around, *args).once }
          it { expect(plugin_instance2).to receive(:a_method).with(:after, *args).once }
        end

      end # with plugin with instance method
    end # #perform

    describe '#clear' do
      context 'with plugin added' do
        let(:plugin) {
          Plugins::Plugin.create {
            before_subject { |*args| call_counter(:before) }
            around_subject { |*args| call_counter(:around); perform_subject }
            after_subject { |*args| call_counter(:after) }
            def call_counter(*args); end
          }
        }

        let(:plugin_instance) { plugins.add(plugin) }
        before { allow(plugin_instance).to receive(:call_counter) }
        subject { plugin_instance }
        after { plugins.perform(:subject, &block) }

        context 'before clear' do
          it { is_expected.to receive(:call_counter).with(:before).once }
          it { is_expected.to receive(:call_counter).with(:around).once }
          it { is_expected.to receive(:call_counter).with(:after).once }
        end

        context 'after clear' do
          before { plugins.clear }
          it { is_expected.not_to receive(:call_counter) }
        end
      end # with plugin added
    end # #clear
  end
end