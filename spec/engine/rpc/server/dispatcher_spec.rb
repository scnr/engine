require 'spec_helper'
require 'fileutils'

require "#{SCNR::Engine::Options.paths.lib}/rpc/server/dispatcher"

describe SCNR::Engine::RPC::Server::Dispatcher do
    before( :each ) do
        SCNR::Engine::Options.system.max_slots = slots
    end

    let(:instance_info_keys) { %w(token pid url owner birthdate helpers now age) }
    let(:slots) { 3 }
    let(:subject) { dispatcher_spawn }

    describe '#alive?' do
        it 'returns true' do
            expect(subject.alive?).to eq(true)
        end
    end

    describe '#preferred' do
        context 'when the dispatcher is a grid member' do
            it 'returns the URL of least burdened Dispatcher' do
                dispatcher_spawn( neighbour: subject.url ).dispatch( '', {}, false )
                dispatcher_spawn( neighbour: subject.url ).dispatch( '', {}, false )

                expect(subject.preferred).to eq(subject.url)
            end

            context 'and all Dispatchers are at max utilization' do
                before :each do
                    subject.dispatch( '', {}, false )
                end

                let(:slots) { 1 }

                it 'returns nil' do
                    dispatcher_spawn( neighbour: subject.url ).dispatch( '', {}, false )
                    dispatcher_spawn( neighbour: subject.url ).dispatch( '', {}, false )

                    expect(subject.preferred).to be_nil
                end
            end
        end

        context 'when the dispatcher is not a grid member' do
            it 'returns the URL of the Dispatcher' do
                expect(subject.preferred).to eq(subject.url)
            end

            context 'and it is at max utilization' do
                before :each do
                    subject.dispatch( '', {}, false )
                end

                let(:slots) { 1 }

                it 'returns nil' do
                    expect(subject.preferred).to be_nil
                end
            end
        end
    end

    describe '#handlers' do
        before :each do
            SCNR::Engine::Options.paths.services = "#{fixtures_path}services/"
        end

        it 'returns an array of loaded handlers' do
            expect(subject.services.include?( 'echo' )).to be_truthy
        end
    end

    describe '#dispatch' do
        it 'does not leak Instances' do
            slots.times do
                subject.dispatch
            end

            expect(subject.instances.size).to eq(slots)
        end

        it 'sets OptionGroups::Dispatcher#url' do
            info = subject.dispatch
            instance = instance_connect( info['url'], info['token'] )

            expect(instance.dispatcher_url).to eq subject.url
        end

        context "when #{SCNR::Engine::OptionGroups::RPC}#server_external_address has been set" do
            before :each do
                SCNR::Engine::Options.rpc.server_external_address = address
            end

            let(:address) { '127.0.0.2' }

            it 'advertises that address' do
                expect(subject.dispatch['url']).to start_with "#{address}:"
            end
        end

        context 'when not a Grid member' do
            it 'returns Instance info' do
                info = subject.dispatch

                %w(token pid url owner birthdate helpers).each do |k|
                    expect(info[k]).to be_truthy
                end

                instance = instance_connect( info['url'], info['token'] )
                expect(instance.alive?).to be_truthy
            end

            it 'assigns an optional owner' do
                owner = 'blah'
                expect(subject.dispatch(owner )['owner']).to eq(owner)
            end

            context 'when the there are no available slots' do
                let(:slots) { 5 }
                before :each do
                    slots.times do
                        subject.dispatch
                    end
                end

                it 'returns nil' do
                    expect(subject.dispatch).to be nil
                end

                context 'and slots are freed' do
                    let(:free) { slots - 1 }

                    it 'returns Instance info' do
                        subject.instances[0...free].each do |info|
                            service = instance_connect( info['url'], info['token'] )
                            service.shutdown

                            while sleep 0.1
                                service.alive? rescue break
                            end
                        end

                        instances = []
                        free.times do
                            instances << subject.dispatch
                        end
                        instances.compact!

                        expect(instances.size).to eq free
                        expect(subject.dispatch).to be nil
                    end
                end
            end
        end

        context 'when a Grid member' do
            let(:slots) { 4 }

            it 'returns Instance info from the least burdened Dispatcher' do
                d1 = dispatcher_spawn(
                    address: '127.0.0.1'
                )

                3.times do
                    d1.dispatch( '', {}, false )
                end

                d2 = dispatcher_spawn(
                    address:   '127.0.0.2',
                    neighbour: d1.url
                )

                2.times do
                    d2.dispatch( '', {}, false )
                end

                d3 = dispatcher_spawn(
                    address:   '127.0.0.3',
                    neighbour: d1.url
                )
                d3.dispatch( '', {}, false )
                preferred = d3.url.split( ':' ).first

                expect(d3.dispatch['url'].split( ':' ).first).to eq(preferred)
                expect(%W{127.0.0.3 127.0.0.2}).to include d1.dispatch['url'].split( ':' ).first
                expect(d2.dispatch['url'].split( ':' ).first).to eq(preferred)
                expect(%W{127.0.0.1 127.0.0.3}).to include d3.dispatch['url'].split( ':' ).first
                expect(%W{127.0.0.2 127.0.0.3}).to include d3.dispatch['url'].split( ':' ).first
                expect(%W{127.0.0.2 127.0.0.3}).to include d1.dispatch['url'].split( ':' ).first
            end

            context 'when the load-balance option is set to false' do
                it 'returns an Instance from the requested Dispatcher' do
                    d1 = dispatcher_spawn(
                        address: '127.0.0.1'
                    )

                    d1.dispatch( '', {}, false )

                    d2 = dispatcher_spawn(
                        address:   '127.0.0.2',
                        neighbour: d1.url
                    )
                    d2.dispatch( '', {}, false )

                    d3 = dispatcher_spawn(
                        address:   '127.0.0.3',
                        neighbour: d1.url
                    )
                    2.times do
                        d3.dispatch( '', {}, false )
                    end

                    expect(d3.dispatch( nil, {}, false )['url'].
                        split( ':' ).first).to eq('127.0.0.3')
                end
            end
        end
    end

    describe '#instance' do
        it 'returns proc info by PID' do
            instance = subject.dispatch
            info = subject.instance( instance['pid'] )
            instance_info_keys.each do |k|
                expect(info[k]).to be_truthy
            end
        end
    end

    describe '#instances' do
        it 'returns proc info by PID for all instances' do
            slots.times { subject.dispatch }

            subject.instances.each do |instance|
                instance_info_keys.each do |k|
                    expect(instance[k]).to be_truthy
                end
            end
        end
    end

    describe '#running_instances' do
        it 'returns proc info for running instances' do
            slots.times { subject.dispatch }

            expect(subject.running_instances.size).to eq(slots)
        end
    end

    describe '#finished_instances' do
        it 'returns proc info for finished instances' do
            3.times { SCNR::Engine::Processes::Manager.kill subject.dispatch['pid'] }

            expect(subject.finished_instances.size).to eq(3)
        end
    end

    describe '#utilization' do
        it 'returns a float signifying the amount of workload' do
            3.times do
                subject.dispatch
            end

            expect(subject.utilization).to eq(3 / Float(slots))
        end
    end

    describe '#statistics' do
        it 'returns general statistics' do
            subject.dispatch
            instances = subject.instances
            SCNR::Engine::Processes::Manager.kill( instances.first['pid'] )

            stats = subject.statistics

            %w(utilization running_instances finished_instances node consumed_pids snapshots).each do |k|
                expect(stats[k]).to be_truthy
            end

            finished = stats['finished_instances']
            expect(finished.size).to eq(1)

            expect(stats['node']).to eq(subject.node.info)
        end

        context 'when there are scan snapshots' do
            it 'lists them' do
                info = subject.dispatch

                instance = SCNR::Engine::RPC::Client::Instance.new(
                    info['url'], info['token']
                )

                instance.scan( url: web_server_url_for( :framework_multi ) )
                instance.suspend
                sleep 1 while !instance.suspended?
                snapshot_path = instance.snapshot_path
                instance.shutdown

                expect(subject.statistics['snapshots']).to include snapshot_path
            end
        end
    end

    describe '#log' do
        it 'returns the contents of the log file' do
            expect(subject.log).to be_truthy
        end
    end

end
