require 'spec_helper'

describe SCNR::Engine::BrowserCluster::Jobs::SinkTrace do

    before do
        SCNR::Engine::Element::DOM::Capabilities::WithSinks::Sinks.enable_all
        SCNR::Engine::Element::DOM::Capabilities::WithSinks::Sinks.add_to_max_cost 9999

        SCNR::Engine::Options.audit.elements :ui_inputs
    end
    
    let(:browser) { SCNR::Engine::Browser.new }
    let(:browser_cluster) { SCNR::Engine::BrowserCluster.new }

    let(:url) do
        SCNR::Engine::Utilities.normalize_url( web_server_url_for( :ui_input_dom ) )
    end

    let(:page) do
        browser.load url
        browser.to_page
    end

    subject do
        described_class.new( args: [page] )
    end

    it 'is of the :crawl category' do
        expect(subject.category).to be :crawl
    end

    context 'when an element is within scope' do
        context 'and has an active DOM' do
            context 'and has not been traced' do
                context 'or is being traced by another thread' do
                    it "forwards elements to #{SCNR::Engine::BrowserCluster::Jobs::SinkTrace::DOMSinkTracer}" do
                        forwarded = false
                        browser_cluster.queue( subject, (proc_to_method do |result|
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

                context 'and is being traced by another thread' do
                    it 'skips it' do
                        parent = page.ui_inputs.first
                        parent.dom.sinks.class.claim parent.dom

                        forwarded = false
                        browser_cluster.queue( subject, (proc_to_method do
                            forwarded = true
                        end))
                        browser_cluster.wait

                        expect(forwarded).to be_falsey
                    end
                end
            end

            context 'and has already been traced' do
                it 'skips it' do
                    e = page.ui_inputs.first.dom
                    e.affected_input_name = e.inputs.first
                    e.sinks.traced!

                    forwarded = false
                    browser_cluster.queue( subject, (proc_to_method do
                        forwarded = true
                    end))
                    browser_cluster.wait

                    expect(forwarded).to be_falsey
                end
            end
        end

        context 'and has had its DOM disabled' do
            it 'skips it' do
                page.ui_inputs.first.skip_dom = true

                forwarded = false
                browser_cluster.queue( subject, (proc_to_method do
                    forwarded = true
                end))
                browser_cluster.wait

                expect(forwarded).to be_falsey
            end
        end
    end

    context 'and is out of scope' do
        it 'skips it' do
            SCNR::Engine::Options.audit.skip_elements :ui_inputs

            forwarded = false
            browser_cluster.queue( subject, (proc_to_method do
                forwarded = true
            end))
            browser_cluster.wait

            expect(forwarded).to be_falsey
        end
    end
end
