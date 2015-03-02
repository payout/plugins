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
        before { 3.times { subject.push(&wrapper) } }

        context 'passing no args to perform_test' do
          let(:wrapper) { Proc.new { |*args| $call_counter.call(*args); perform_test } }
          after { subject.call(*args, &block) }

          it 'should call block' do
            expect(block).to receive(:call).with(*args).once
          end

          it 'should execute all wrappers' do
            expect(call_counter).to receive(:call).with(*args).exactly(3).times
          end
        end # passing no args to perform_test

        context 'passing incremented counter to perform_test' do
          let(:wrapper) { Proc.new { |counter| $call_counter.call(counter); perform_test(counter + 1) } }
          after { subject.call(0, &block) }

          it 'should call block with incremented counter' do
            expect(block).to receive(:call).with(3).once
          end

          it 'should execute all wrappers' do
            expect(call_counter).to receive(:call).with(0).once
            expect(call_counter).to receive(:call).with(1).once
            expect(call_counter).to receive(:call).with(2).once
          end
        end # passing incremented counter to perform_test
      end # with three wrappers in stack
    end # #call

    describe AroundStack::AroundWrapper do
      describe '#call' do
        context 'with empty call stack' do
          let(:wrapper) { AroundStack::AroundWrapper.new(:subject) }
          subject { wrapper.call([]) }

          it 'should raise exception' do
            expect { subject }.to raise_error(Errors::Error, 'call stack too short')
          end
        end
      end
    end # AroundStack::AroundWrapper

    describe AroundStack::WrappedBlock do
      describe '#call' do
        context 'with non-empty call stack' do
          let(:wrapped) { AroundStack::WrappedBlock.new {} }
          subject { wrapped.call([1]) }
          it 'should raise error' do
            expect { subject }.to raise_error(Errors::Error, 'receiving non-empty call stack')
          end
        end # with non-empty call stack
      end
    end
  end
end