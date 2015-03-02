class Ribbon::Plugins
  RSpec.describe AroundStack do
    let(:stack) { AroundStack.new(:test) }
    subject { stack }

    describe '#push' do
      it 'raise error when no wrapper passed' do
        expect { subject.push }.to raise_error(Errors::Error, "Must pass block")
      end

      it 'should accept a block' do
        expect(subject.push {}).to be_a AroundStack::AroundWrapper
      end
    end

    describe '#call' do
      let(:args) { [1, :two, 'three'] }
      let(:block) { Proc.new {} }

      context 'without passed block' do
        subject { stack.call(*args) }
        it 'should raise error' do
          expect { subject }.to raise_error(Errors::Error, "Must pass block")
        end
      end

      context 'with empty stack' do
        after { subject.call(*args, &block) }

        it 'should execute the block' do
          expect(block).to receive(:call).with(*args).once
        end
      end

      context 'with three wrappers in stack' do
        # Need to use a separate call_counter because AroundStack doesn't call
        # the blocks, it runs instance_exec on itself instead.
        let(:call_counter) { double('call_counter') }
        before { allow(call_counter).to receive(:call) }

        # Make call_counter available to wrapper block
        before { $call_counter = call_counter }
        let(:wrapper) { Proc.new { |*args| $call_counter.call(*args); perform_test } }


        before { 3.times { subject.push(&wrapper) } }

        after { subject.call(*args, &block) }

        it 'should call block' do
          expect(block).to receive(:call).with(*args).once
        end

        it 'should execute all wrappers' do
          expect(call_counter).to receive(:call).with(*args).exactly(3).times
        end
      end
    end
  end
end