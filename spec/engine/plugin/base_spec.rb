require 'spec_helper'

describe SCNR::Engine::Plugin::Base do
    before( :each ) do
        SCNR::Engine::Options.url = url
        framework.plugins.load_default
    end

    subject { described_class.new( framework, {} ) }
    let(:url) { web_server_url_for(:framework) }
    let(:framework) { SCNR::Engine::Framework.new.tap { |f| f.state.running = true } }

    describe '#info' do
        it 'returns .info' do
            expect(subject.info).to eq(described_class.info)
        end
    end

    describe '#session' do
        it "returns #{SCNR::Engine::Framework}#session" do
            expect(subject.session).to eq(framework.session)
        end
    end

    describe '#http' do
        it "returns #{SCNR::Engine::Framework}#http" do
            expect(subject.http).to eq(framework.http)
        end
    end

    describe '#framework_pause' do
        it 'pauses the framework' do
            expect(framework).to receive(:pause)
            subject.framework_pause
        end
    end

    describe '#framework_resume' do
        it 'resumes the framework' do
            framework.run

            subject.framework_pause

            expect(framework).to receive(:resume)
            subject.framework_resume
        end
    end

    describe '#wait_while_framework_running' do
        it 'blocks while the framework runs' do
            expect(framework).to be_running

            q = Queue.new
            Thread.new do
                subject.wait_while_framework_running
                q << nil
            end

            framework.state.running = false

            Timeout.timeout 2 do
                q.pop
            end

            expect(framework).not_to be_running
        end
    end

end
