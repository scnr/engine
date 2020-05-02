require 'spec_helper'
require "#{SCNR::Engine::Options.paths.lib}/rpc/server/base"

describe SCNR::Engine::RPC::Server::Base do
    before( :each ) do
        Arachni::Reactor.global.run_in_thread
    end

    let(:subject) { SCNR::Engine::RPC::Server::Base.new(
        host: 'localhost', port: port
    ) }
    let(:port) { available_port }

    it 'supports UNIX sockets', if: Arachni::Reactor.supports_unix_sockets? do
        server = SCNR::Engine::RPC::Server::Base.new(
            socket: "#{Dir.tmpdir}/scnr-engine-base-#{SCNR::Engine::Utilities.generate_token}"
        )

        server.start

        raised = false
        begin
            Timeout.timeout( 20 ){
                sleep 0.1 while !server.ready?
            }
        rescue Exception => e
            raised = true
        end

        expect(server.ready?).to be_truthy
        expect(raised).to be_falsey
    end

    describe '#ready?' do
        context 'when the server is not ready' do
            it 'returns false' do
                expect(subject.ready?).to be_falsey
            end
        end

        context 'when the server is ready' do
            it 'returns true' do
                subject.start

                raised = false
                begin
                    Timeout.timeout( 20 ){
                        sleep 0.1 while !subject.ready?
                    }
                rescue Exception => e
                    raised = true
                end

                expect(subject.ready?).to be_truthy
                expect(raised).to be_falsey
            end
        end
    end

end
