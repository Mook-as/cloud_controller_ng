require 'spec_helper'

module VCAP::CloudController::InstancesReporter
  describe LegacyInstancesReporter do

    subject { described_class.new(health_manager_client) }
    let(:app) { VCAP::CloudController::AppFactory.make(:package_hash => "abc", :package_state => "STAGED") }
    let(:health_manager_client) { double(:health_manager_client) }

    describe '#all_instances_for_app' do
      let(:instances) do
        {
          0 => {
            :state => 'RUNNING',
            :since => 1,
          },
        }
      end

      before do
        allow(VCAP::CloudController::DeaClient).to receive(:find_all_instances).and_return(instances)
      end

      it 'uses DeaClient to return instances' do
        response = subject.all_instances_for_app(app)

        expect(VCAP::CloudController::DeaClient).to have_received(:find_all_instances).with(app)
        expect(instances).to eq(response)
      end
    end

    describe '#number_of_starting_and_running_instances_for_app' do
      context 'when the app is not started' do
        before do
          app.state = 'STOPPED'
        end

        it 'returns 0' do
          result = subject.number_of_starting_and_running_instances_for_app(app)

          expect(result).to eq(0)
        end
      end

      context 'when the app is started' do
        before do
          app.state = 'STARTED'
          allow(health_manager_client).to receive(:healthy_instances).and_return(5)
        end

        it 'asks the health manager for the number of healthy_instances and returns that' do
          result = subject.number_of_starting_and_running_instances_for_app(app)

          expect(health_manager_client).to have_received(:healthy_instances).with(app)
          expect(result).to eq(5)
        end
      end

    end

    describe '#crashed_instances_for_app' do
      before do
        allow(health_manager_client).to receive(:find_crashes).and_return('some return value')
      end

      it 'asks the health manager for the crashed instances and returns that' do
        result = subject.crashed_instances_for_app(app)

        expect(health_manager_client).to have_received(:find_crashes).with(app)
        expect(result).to eq('some return value')
      end
    end

    describe '#stats_for_app' do

      before do
        allow(VCAP::CloudController::DeaClient).to receive(:find_stats).and_return('some return value')
      end

      it 'uses DeaClient to return stats' do
        result = subject.stats_for_app(app)

        expect(VCAP::CloudController::DeaClient).to have_received(:find_stats).with(app)
        expect(result).to eq('some return value')
      end
    end
  end
end