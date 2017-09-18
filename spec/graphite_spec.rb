require 'spec_helper'
require 'lookout/rack/utils/graphite'

describe Lookout::Rack::Utils::Graphite do
  let(:statsd_instance) { nil }
  subject(:graphite) { described_class }

  before :each do
    configatron.statsd.prefix = 'test'
    Lookout::Statsd.clear_instance
    described_class.clear_instance
    Lookout::Statsd.set_instance(statsd_instance)
    graphite.instance # Initialize statsd singleton
  end

  after :each do
    Lookout::Statsd.clear_instance
    described_class.clear_instance
  end

  context "without configuring statsd_instance" do
    context 'offers statsd methods' do
      it { should respond_to :increment }
      it { should respond_to :decrement }
      it { should respond_to :timing }
      it { should respond_to :time }
      it { should respond_to :update_counter }
    end

    it 'should delegate to statsd' do
      expect_any_instance_of(Lookout::StatsdClient).to receive(:increment).once.with('device.associated')
      Lookout::Rack::Utils::Graphite.increment('device.associated')
    end

    describe '#time' do
      it 'should delegate the block to statsd' do
        expect { |block|
          expect_any_instance_of(Lookout::StatsdClient).to receive(:time).once.with('device.became_aware', &block)
          Lookout::Rack::Utils::Graphite.time('device.became_aware', &block)
        }.to yield_control
      end

      it 'should delegate the sample rate and block to statsd' do
        expect { |block|
          expect_any_instance_of(Lookout::StatsdClient).to receive(:time).once.with('device.became_aware', 0.05, &block)
          Lookout::Rack::Utils::Graphite.time('device.became_aware', 0.05, &block)
        }.to yield_control
      end
    end
  end

  context "setting statsd_instance" do
    let(:statsd_instance) { double('Statsd',
                                   :increment => true,
                                   :decrement => true,
                                   :time => true,
                                   :timing => true,
                                   :update_counter => true) }

    context 'offers statsd methods' do
      it { should respond_to :increment }
      it { should respond_to :decrement }
      it { should respond_to :time }
      it { should respond_to :timing }
      it { should respond_to :update_counter }
    end

    it 'should delegate to statsd' do
      expect(statsd_instance).to receive(:increment).once.with('device.associated')
      Lookout::Rack::Utils::Graphite.increment('device.associated')
    end

    describe '#time' do
      it 'should delegate the block to statsd' do
        expect { |block|
          expect(statsd_instance).to receive(:time).once.with('device.became_aware', &block)
          Lookout::Rack::Utils::Graphite.time('device.became_aware', &block)
        }.to yield_control
      end

      it 'should delegate the sample rate and block to statsd' do
        expect { |block|
          expect(statsd_instance).to receive(:time).once.with('device.became_aware', 0.05, &block)
          Lookout::Rack::Utils::Graphite.time('device.became_aware', 0.05, &block)
        }.to yield_control
      end
    end
  end
end
