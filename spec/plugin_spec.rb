class Ribbon::Plugins
  RSpec.describe Plugin do
    let(:args) { [1, :two, 'three'] }

    let(:callback) { Proc.new {} }
    before { $callback = callback }

    describe '#create' do
      context 'with no block' do
        subject { Plugin.create }

        it 'should raise error' do
          expect { subject }.not_to raise_error
        end
      end
    end

    describe '#before' do
      context 'with no callbacks' do
        subject { Plugin.new }
        it 'should not raise error' do
          expect { subject.before(:subject, *args) }.not_to raise_error
        end
      end

      context 'with three callbacks' do
        subject {
          Plugin.create {
            before_subject(&$callback)
            before_subject(&$callback)
            before_subject(&$callback)
          }.new
        }

        after { subject.before(:subject, *args) }

        it 'should call all three callbacks' do
          expect(callback).to receive(:call).with(*args).exactly(3).times
        end
      end
    end # #before

    describe '#after' do
      context 'with no callbacks' do
        subject { Plugin.new }
        it 'should not raise error' do
          expect { subject.after(:subject, *args) }.not_to raise_error
        end
      end

      context 'with three callbacks' do


        subject {
          Plugin.create {
            after_subject(&$callback)
            after_subject(&$callback)
            after_subject(&$callback)
          }.new
        }

        after { subject.after(:subject, *args) }

        it 'should call all three callbacks' do
          expect(callback).to receive(:call).with(*args).exactly(3).times
        end
      end
    end # #after

    describe '#around' do
      let(:block) { Proc.new {} }

      # Need to use a separate call_counter because AroundStack doesn't call
      # the blocks, it runs instance_exec on itself instead.
      let(:call_counter) { double('call_counter') }
      before { allow(call_counter).to receive(:call) }

      # Make call_counter available to callback block
      before { $call_counter = call_counter }
      let(:callback) { Proc.new { |*args| $call_counter.call(*args); perform_subject } }

      before { $callback = callback }

      subject { plugin.around(:subject, *args, &block) }
      after { subject }

      context 'with no callbacks' do
        let(:plugin) { Plugin.new }

        it 'should not raise error' do
          expect { subject }.not_to raise_error
        end

        it 'should call block' do
          expect(block).to receive(:call).with(*args).once
        end
      end # with no callbacks

      context 'with three callbacks' do
        let(:plugin) {
          Plugin.create {
            around_subject(&$callback)
            around_subject(&$callback)
            around_subject(&$callback)
          }.new
        }

        it 'should call block' do
          expect(block).to receive(:call).with(*args).once
        end

        it 'should call all three callbacks' do
          expect(call_counter).to receive(:call).with(*args).exactly(3).times
        end
      end # with three callbacks
    end
  end
end