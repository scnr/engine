require 'spec_helper'

describe SCNR::Engine::BrowserPool::Jobs::DOMExploration::EventTrigger do
    before :each do
        SCNR::Engine::Element::DOM::Capabilities::WithSinks::Sinks.enable_all
        SCNR::Engine::Element::DOM::Capabilities::WithSinks::Sinks.add_to_max_cost 9999
    end

    let(:browser) { SCNR::Engine::Browser.new }
    let(:browser_pool) { SCNR::Engine::BrowserPool.new }
    
    let(:url) do
        SCNR::Engine::Utilities.normalize_url( web_server_url_for( :event_trigger ) )
    end
    let(:event) do
        browser.load url
        browser.each_element_with_events { |_, events| return events.first.first }
        nil
    end
    let(:element) do
        browser.load url
        browser.each_element_with_events { |element, _| return element }
        nil
    end

    let(:sink_trace_url) do
        SCNR::Engine::Utilities.normalize_url( web_server_url_for( :ui_input_dom ) )
    end
    let(:sink_trace_event) do
        browser.load sink_trace_url
        browser.each_element_with_events { |_, events| return events.first.first }
        nil
    end
    let(:sink_trace_element) do
        browser.load sink_trace_url
        browser.each_element_with_events { |element, _| return element }
        nil
    end

    def test( job )
        pages = []

        browser_pool.queue( job, (proc_to_method do |result|
            expect(result).to be_kind_of described_class::Result
            pages << result.page
        end))
        browser_pool.wait

        expect(pages.size).to eq(1)

        page = pages.first

        expect(page.dom.transitions.size).to eq(2)

        expect(page.dom.transitions[1].event).to eq(event)

        expect(Nokogiri::HTML( page.body ).xpath("//div").first.to_s).to eq(
            '<div id="my-div"><a href="#1">My link</a></div>'
        )
    end

    it "forwards pages to a #{SCNR::Engine::BrowserPool::Jobs::SinkTrace}" do
        SCNR::Engine::Options.audit.elements :ui_inputs

        forwarded = false
        browser_pool.queue(
            described_class.new(
                element:  sink_trace_element,
                event:    sink_trace_event,
                resource: sink_trace_url
            ), (proc_to_method do |result|
            next if !result.page.element_sink_trace_hash

            e = result.page.ui_inputs.first.dom

            expect(e.sinks).to be_traced
            expect(e.sinks).to be_active
            expect(e.sinks).to be_body

            expect(result.page.element_sink_trace_hash).to eq e.sink_hash

            forwarded = true
        end))
        browser_pool.wait

        expect(forwarded).to be_truthy
    end

    context 'when the resource is a' do
        context 'String' do
            it 'loads the URL and triggers the given event on the given element' do
                test described_class.new( resource: url, event: event, element: element )
            end
        end

        context 'Engine::HTTP::Response' do
            it 'loads it and triggers the given event on the given element' do
                test described_class.new(
                         resource: SCNR::Engine::HTTP::Client.get( url, mode: :sync ),
                         event:    event,
                         element:  element
                     )
            end
        end

        context 'Engine::Page' do
            it 'loads it and triggers the given event on the given element' do
                test described_class.new(
                    resource: SCNR::Engine::Page.from_url( url ),
                    event:    event,
                    element:  element
                )
            end
        end
    end
end
