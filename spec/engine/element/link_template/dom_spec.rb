require 'spec_helper'

describe SCNR::Engine::Element::LinkTemplate::DOM do
    inputs = { 'param' => 'some-name' }

    it_should_behave_like 'element_dom'

    it_should_behave_like 'with_node'
    it_should_behave_like 'with_auditor'
    it_should_behave_like 'with_sinks'

    it_should_behave_like 'with_locator'
    it_should_behave_like 'submittable_dom'
    it_should_behave_like 'inputtable_dom', inputs: inputs
    it_should_behave_like 'mutable_dom',    inputs: inputs
    it_should_behave_like 'auditable_dom'

    def auditable_extract_parameters( page )
        { 'param' => Nokogiri::HTML(page.body).css('#container').text }
    end

    def run
        auditor.browser_pool.wait
    end

    before :each do
        enable_dom
        SCNR::Engine::Framework.unsafe.reset

        SCNR::Engine::Options.audit.link_template_doms = [
            /param\/(?<param>.+)/,
            /input1\/(?<input1>.+)\/input2\/(?<input2>.+)/,
            /active\/(?<active>.+)\/blind\/(?<blind>.+)/
        ]
    end

    subject { page.link_templates.first.dom.tap { |l| l.auditor = auditor } }
    let(:page) { SCNR::Engine::Page.from_url( url ) }
    let(:framework) { SCNR::Engine::Framework.unsafe }
    let(:auditor) { Auditor.new( page ) }
    let(:parent) { subject.parent }
    let(:url) { web_server_url_for( :link_template_dom ) }
    let(:inputtable) do
        l = SCNR::Engine::Page.from_url( "#{url}/inputtable" ).link_templates.first.dom
        l.auditor = auditor
        l
    end

    let(:with_sinks) do
        l = SCNR::Engine::Page.from_url( "#{url}/link/sinks/body" ).link_templates.first.dom
        l.auditor = auditor
        l
    end
    let(:with_sinks_in_body) do
        with_sinks
    end
    let(:with_sinks_blind) do
        l = SCNR::Engine::Page.from_url( "#{url}/link/sinks/blind" ).link_templates.first.dom
        l.auditor = auditor
        l
    end
    let(:with_sinks_active) do
        l = SCNR::Engine::Page.from_url( "#{url}/link/sinks/active" ).link_templates.first.dom
        l.auditor = auditor
        l
    end

    let(:mutable) do
        subject.dup
    end

    describe '#type' do
        it 'returns :link_dom' do
            expect(subject.type).to eq(:link_template_dom)
        end
    end

    describe '.type' do
        it 'returns :link_dom' do
            expect(described_class.type).to eq(:link_template_dom)
        end
    end

    describe '#extract_inputs' do
        it "delegates to #{SCNR::Engine::Element::LinkTemplate}.extract_inputs" do
            subject

            allow(SCNR::Engine::Element::LinkTemplate).to receive(:extract_inputs) { |arg| "#{arg}1" }
            expect(subject.extract_inputs( 'blah' )).to eq('blah1')
        end
    end

    describe '#parent' do
        it 'returns the parent element' do
            expect(subject.parent).to be_kind_of SCNR::Engine::Element::LinkTemplate
        end
    end

    describe '#inputs' do
        it 'parses query-style inputs from URL fragments' do
            expect(subject.inputs).to eq({ 'param' => 'some-name' })
        end
    end

    describe '#fragment' do
        it 'returns the URL fragment' do
            expect(subject.fragment).to eq('/param/some-name')
        end
    end

    describe '#trigger' do
        it 'triggers the event required to submit the element' do
            inputs = { 'param' => 'The.Dude' }
            subject.update inputs

            called = false
            subject.with_browser do |browser|
                subject.browser = browser

                subject.trigger

                expect(subject.inputs).to eq(auditable_extract_parameters( browser.to_page ))
                called = true
            end

            subject.auditor.browser_pool.wait
            expect(called).to be_truthy
        end

        it 'returns a playable transition' do
            inputs = { 'param'  => 'The.Dude' }
            subject.update inputs

            transitions = []
            called = false
            subject.with_browser do |browser|
                subject.browser = browser
                browser.load subject.page

                transitions = subject.trigger

                page = browser.to_page

                expect(subject.inputs).to eq(auditable_extract_parameters( page ))
                called = true
            end

            subject.auditor.browser_pool.wait
            expect(called).to be_truthy

            called = false
            auditor.with_browser do |browser|
                browser.load subject.page
                expect(auditable_extract_parameters( browser.to_page )).to eq(
                    { 'param' => '' }
                )

                transitions.each do |transition|
                    transition.play browser
                end

                expect(auditable_extract_parameters( browser.to_page )).to eq(inputs)
                called = true
            end
            auditor.browser_pool.wait
            expect(called).to be_truthy
        end
    end

    describe '.to_rpc_data' do
        it 'converts the #template to a string' do
            expect(subject.to_rpc_data['template']).to eq(subject.template.source)
        end
    end

    describe '.data_from_node' do
        let(:node) { subject.node }
        let(:data) { described_class.data_from_node( node ) }

        it 'returns a hash with DOM data' do
            expect(data).to eq({
                inputs:   {
                    'param' => 'some-name'
                },
                template: /param\/(?<param>.+)/,
                fragment: '/param/some-name'
            })
        end

        it 'decodes the fragment before extracting inputs' do
            html = "<a href='#/param/bl%20ah'>Stuff</a>"
            node = Nokogiri::HTML.fragment(html).children.first

            expect(described_class.data_from_node( node )[:inputs]).to eq({
                'param' => 'bl ah'
            })
        end

        context 'when there is no URL fragment' do
            let(:node) do
                Nokogiri::HTML.fragment( "<a href='/stuff/here'>Stuff</a>" ).
                    children.first
            end

            it 'return nil' do
                expect(described_class.data_from_node( node )).to be_nil
            end
        end

        context 'when there are no inputs' do
            let(:node) do
                Nokogiri::HTML.fragment( "<a href='#/param2/val'>Stuff</a>" ).
                    children.first
            end

            it 'return nil' do
                expect(described_class.data_from_node( node )).to be_nil
            end
        end
    end

end
