class Ribbon::Plugins
  RSpec.describe Plugin do
    let(:args) { [1, :two, 'three'] }

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
            before_subject { |*args| call_counter(*args) }
            before_subject { |*args| call_counter(*args) }
            before_subject { |*args| call_counter(*args) }

            def call_counter(*args); end
          }.new
        }

        after { subject.before(:subject, *args) }

        it { is_expected.to receive(:call_counter).with(*args).exactly(3).times }
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
            after_subject { |*args| call_counter(*args) }
            after_subject { |*args| call_counter(*args) }
            after_subject { |*args| call_counter(*args) }

            def call_counter(*args); end
          }.new
        }

        after { subject.after(:subject, *args) }

        it { is_expected.to receive(:call_counter).with(*args).exactly(3).times }
      end
    end # #after

    describe '#around' do
      let(:block) { Proc.new {} }

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
            around_subject { |*args| call_counter(*args); perform_subject }
            around_subject { |*args| call_counter(*args); perform_subject }
            around_subject { |*args| call_counter(*args); perform_subject }
            def call_counter(*args); end
          }.new
        }

        it 'should call block' do
          expect(block).to receive(:call).with(*args).once
        end

        it 'should execute all three callbacks' do
          expect(plugin).to receive(:call_counter).with(*args).exactly(3).times
        end
      end # with three callbacks
    end
  end
end