module Ribbon
  RSpec.describe Plugins do
    let(:args) { [1, :two, 'three'] }
    let(:block) { Proc.new {} }

    describe '#around' do
      # Need to use a separate call_counter because AroundStack doesn't call
      # the blocks, it runs instance_exec on itself instead.
      let(:call_counter) { double('call_counter') }
      before { allow(call_counter).to receive(:call) }

      # Make call_counter available to callback block
      before { $call_counter = call_counter }
      let(:callback) { Proc.new { |*args| $call_counter.call(*args); perform_subject } }

      before { $callback = callback }

      subject { plugins.around(:subject, *args, &block) }
      after { subject }

      context 'with no plugins' do
        let(:plugins) { Plugins.new }
        it 'should run block' do
          expect(block).to receive(:call).with(*args).once
        end
      end # with no plugins

      context 'with empty plugin' do
        let(:plugin) { Plugins::Plugin.create }
        let(:plugins) { Plugins.new.tap {|p| p.add(plugin) } }

        it 'should run block' do
          expect(block).to receive(:call).with(*args).once
        end
      end # with empty plugin

      context 'with non-empty plugin' do
        let(:plugin) {
          Plugins::Plugin.create {
            around_subject { |*args|
              $call_counter.call(*args)
              perform_subject
            }
          }
        }

        let(:plugins) { Plugins.new.tap {|p| p.add(plugin) } }

        it 'should run block' do
          expect(block).to receive(:call).with(*args).once
        end

        it 'should run plugin callback' do
          expect(call_counter).to receive(:call).with(*args).once
        end
      end # with non-empty plugin

      context 'with three plugins' do
        let(:plugin) {
          Plugins::Plugin.create {
            around_subject { |*args|
              $call_counter.call(*args)
              perform_subject
            }
          }
        }

        let(:plugins) { Plugins.new.tap {|p| p.add(plugin); p.add(plugin); p.add(plugin) } }

        it 'should run block' do
          expect(block).to receive(:call).with(*args).once
        end

        it 'should run plugin callback' do
          expect(call_counter).to receive(:call).with(*args).exactly(3).times
        end
      end # with three plugins
    end

    describe '#perform' do
      subject { Plugins.new }
      after { subject.perform(:subject, *args, &block) }

      it { is_expected.to receive(:before).with(:subject, *args, &block).once }
      it { is_expected.to receive(:around).with(:subject, *args, &block).once }
      it { is_expected.to receive(:after).with(:subject, *args, &block).once }
    end
  end
end