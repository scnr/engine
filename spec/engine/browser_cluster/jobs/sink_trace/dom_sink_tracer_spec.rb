require 'spec_helper'

describe SCNR::Engine::BrowserPool::Jobs::SinkTrace::DOMSinkTracer do

    before do
        SCNR::Engine::Element::DOM::Capabilities::WithSinks::Sinks.enable_all
        SCNR::Engine::Element::DOM::Capabilities::WithSinks::Sinks.add_to_max_cost 9999

        SCNR::Engine::Options.audit.elements :ui_inputs
    end

    let(:url) do
        SCNR::Engine::Utilities.normalize_url( web_server_url_for( :ui_input_dom ) )
    end

    let(:browser) { SCNR::Engine::Browser.new }
    let(:browser_pool) { SCNR::Engine::BrowserPool.new }

    let(:page) do
        browser.load url
        browser.to_page
    end

    let(:element) do
        page.ui_inputs.first
    end

    subject do
        described_class.new( page: page, element: element )
    end

    it 'is of the :crawl category' do
        expect(subject.category).to be :crawl
    end

    context 'when an element has not been traced' do
        context 'or is being traced by another thread' do
            it 'traces its sinks' do
                forwarded = false
                browser_pool.queue( subject, (proc_to_method do |result|
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
        end

        context 'and is being traced by another thread' do
            it 'skips it' do
                parent = page.ui_inputs.first
                parent.dom.sinks.class.claim parent.dom

                forwarded = false
                browser_pool.queue( subject, (proc_to_method do
                    forwarded = true
                end))
                browser_pool.wait

                expect(forwarded).to be_falsey
            end
        end
    end

    context 'when an element has already been traced' do
        it 'skips it' do
            e = page.ui_inputs.first.dom
            e.affected_input_name = e.inputs.first
            e.sinks.traced!

            forwarded = false
            browser_pool.queue( subject, (proc_to_method do
                forwarded = true
            end))
            browser_pool.wait

            expect(forwarded).to be_falsey
        end
    end

end
