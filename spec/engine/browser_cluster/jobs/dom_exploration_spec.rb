require 'spec_helper'

describe SCNR::Engine::BrowserCluster::Jobs::DOMExploration do
    before do
        SCNR::Engine::Element::DOM::Capabilities::WithSinks::Sinks.add_to_max_cost 9999
    end

    let(:browser_cluster) { SCNR::Engine::BrowserCluster.new }
    let(:url) do
        SCNR::Engine::Utilities.normalize_url( web_server_url_for( :browser ) ) + 'explore'
    end
    let(:sink_trace_url) do
        SCNR::Engine::Utilities.normalize_url( web_server_url_for( :ui_input_dom ) )
    end

    def test( job )
        pages = []
        has_event_triggers = false

        browser_cluster.queue( job, (proc_to_method do  |result|
            expect(result).to be_kind_of described_class::Result

            if result.job.is_a? described_class::EventTrigger
                has_event_triggers = true
                expect(result.job.forwarder).to be_kind_of described_class
            end

            pages << result.page
        end))
        browser_cluster.wait

        expect(has_event_triggers).to be_truthy
        browser_explore_check_pages pages
    end

    context "when #{SCNR::Engine::Element::DOM::Capabilities::WithSinks::Sinks}" do
        context 'have been enabled' do
            before do
                SCNR::Engine::Element::DOM::Capabilities::WithSinks::Sinks.enable_all
            end

            it "forwards pages to a #{SCNR::Engine::BrowserCluster::Jobs::SinkTrace}" do
                SCNR::Engine::Options.audit.elements :ui_inputs

                forwarded = false
                browser_cluster.queue( described_class.new( resource: sink_trace_url ), (proc_to_method do |result|
                    next if !result.page.element_sink_trace_hash

                    e = result.page.ui_inputs.first.dom

                    expect(e.sinks).to be_traced
                    expect(e.sinks).to be_active
                    expect(e.sinks).to be_body

                    expect(result.page.element_sink_trace_hash).to eq e.sink_hash

                    forwarded = true
                end))
                browser_cluster.wait

                expect(forwarded).to be_truthy
            end
        end

        context 'have not been enabled' do
            it "does not forward pages to a #{SCNR::Engine::BrowserCluster::Jobs::SinkTrace}"
        end
    end

    context 'when the resource is a' do
        context 'String' do
            it 'loads the URL and explores the DOM' do
                test described_class.new( resource: url )
            end
        end

        context 'Engine::HTTP::Response' do
            subject do
                described_class.new(
                    resource: SCNR::Engine::HTTP::Client.get( url, mode: :sync )
                )
            end

            it 'loads it and explores the DOM' do
                test subject
            end

            it "can be stored to disk by the #{SCNR::Engine::Support::Database::Queue}" do
                q = SCNR::Engine::Support::Database::Queue.new
                q.max_buffer_size = 0

                q << subject

                restored = q.pop
                expect(restored).to eq(subject)
            end
        end

        context 'Engine::Page' do
            let(:page) { SCNR::Engine::Page.from_url( url ) }
            subject { described_class.new( resource: page ) }

            it 'only stores the DOM' do
                expect(subject.resource).to eq page.dom
            end

            it 'loads it and explores the DOM' do
                test subject
            end

            it "can be stored to disk by the #{SCNR::Engine::Support::Database::Queue}" do
                q = SCNR::Engine::Support::Database::Queue.new
                q.max_buffer_size = 0

                q << subject

                restored = q.pop
                expect(restored).to eq(subject)
            end
        end
    end
end
