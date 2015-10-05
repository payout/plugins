class Plugins
  RSpec.describe ComponentMixin do
    let(:component_class) {
      Class.new {
        include ComponentMixin
        def an_instance_method(*args); end
      }
    }

    let(:component) { component_class.new }
    let(:plugins) { component.plugins }

    describe '#plugins' do
      subject { plugins }

      context 'without plugin_loader defined' do
        it { is_expected.to be_a Plugins }
        it { is_expected.to have_attributes(component: component) }
        it { is_expected.to have_attributes(plugin_loader: nil) }
      end # without plugin_loader defined

      context 'with plugin_loader defined' do
        let(:plugin_loader) { Proc.new {} }
        before { component_class.plugin_loader(&plugin_loader) }
        it { is_expected.to be_a Plugins }
        it { is_expected.to have_attributes(component: component)}
        it { is_expected.to have_attributes(plugin_loader: plugin_loader) }
      end # with plugin_loader defined
    end # #plugins

    describe '#plugin' do
      let(:additional_args) { [] }
      subject { component.plugin(plugin, *additional_args) }

      context 'without plugin_loader defined' do
        context 'with valid plugin' do
          let(:plugin) {
            Plugin.create {
              def initialize(plugins, *args)
                super(plugins)
              end
            }
          }
          after { subject }

          context 'without additional args' do
            it 'should pass plugin on to Plugins#add' do
              expect(plugins).to receive(:add).with(plugin).once
            end

            it 'should only pass plugins instance to initializer' do
              expect(plugin).to receive(:new).with(plugins).once
            end
          end # without additional args

          context 'with additional args' do
            let(:additional_args) { [1, :two, 'three'] }
            it 'should pass additional args to plugin initializer' do
              expect(plugin).to receive(:new).with(*([plugins] + additional_args)).once
            end
          end # with additional args
        end # with valid plugin

        context 'with plugin block' do
          subject { component.plugin { def test_method; end } }
          it { is_expected.to be_a Plugin }
          it { is_expected.to respond_to(:test_method) }
        end # with plugin block

        context 'with invalid plugin' do
          let(:plugin) { Class.new }

          it 'should raise exception' do
            expect { subject }.to raise_error(
              Errors::LoadError,
              /^Invalid plugin class: #<Class:.*> Must extend Plugin.$/
            )
          end
        end # with invalid plugin
      end # without plugin_loader defined

      context 'with plugin_loader defined' do
        let(:plugin_loader) { Proc.new { |*args| an_instance_method(*args) } }
        before { component_class.plugin_loader(&plugin_loader) }

        context 'with valid plugin' do
          let(:plugin) { Plugin.create }
          after { subject }

          it 'should call plugin_loader once' do
            expect(component).to receive(:an_instance_method).with(plugin).once
          end
        end # with valid plugin

        context 'with invalid plugin' do
          let(:plugin) { Class.new }

          it 'should call plugin_loader once before raising exception' do
            expect(component).to receive(:an_instance_method).with(plugin).once
            expect { subject }.to raise_error
          end
        end # with invalid plugin
      end # with plugin_loader defined
    end # #plugin
  end # ComponentMixin
end # Plugins
