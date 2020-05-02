require 'spec_helper'
require 'fileutils'

describe SCNR::Engine::RPC::Client::Dispatcher do
    before( :each ) do
        SCNR::Engine::Options.paths.services = "#{fixtures_path}services/"
    end

    subject { dispatcher_spawn }

    it 'maps the remote handlers to local objects' do
        args = [ 'stuff', 'here', { 'blah' => true } ]
        expect(subject.echo.echo( *args )).to eq(args)
    end

    describe '#node' do
        it 'provides access to the node data' do
            expect(subject.node.info.is_a?( Hash )).to be_truthy
        end
    end

end
