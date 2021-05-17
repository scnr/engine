require 'spec_helper'

describe SCNR::Engine::Element::Form::DOM do
    inputs = { 'param' => '1' }

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
        YAML.load( Nokogiri::HTML(page.body).css( 'body' ).text )
    end

    def run
        auditor.browser_cluster.wait
    end

    def get_form_dom( url )
        f = SCNR::Engine::Page.from_url( url ).forms.first
        f.skip_dom = false
        f.dom
    end

    before(:each) { enable_browser_cluster }

    subject do
        f = page.forms.first
        f.skip_dom = false
        form = f.dom
        form.auditor = auditor
        form
    end
    let(:page) { SCNR::Engine::Page.from_url( "#{url}/form" ) }
    let(:framework) { SCNR::Engine::Framework.unsafe }
    let(:auditor) { Auditor.new( page, framework ) }
    let(:parent) { subject.parent }
    let(:url) { web_server_url_for( :form_dom ) }
    let(:inputtable) do
        f = get_form_dom( "#{url}/form/inputtable" )
        f.auditor = auditor
        f
    end

    let(:with_sinks) do
        f = get_form_dom( "#{url}/sinks/body" )
        f.auditor = auditor
        f
    end

    let(:with_sinks_in_body) do
        with_sinks
    end

    let(:with_sinks_active) do
        f = get_form_dom( "#{url}/sinks/active" )
        f.auditor = auditor
        f
    end

    let(:with_sinks_blind) do
        f = get_form_dom( "#{url}/sinks/blind" )
        f.auditor = auditor
        f
    end

    describe '#type' do
        it 'returns :form_dom' do
            expect(subject.type).to eq(:form_dom)
        end
    end

    describe '.type' do
        it 'returns :form_dom' do
            expect(described_class.type).to eq(:form_dom)
        end
    end

    describe '#parent' do
        it 'returns the parent element' do
            expect(subject.parent).to be_kind_of SCNR::Engine::Element::Form
        end
    end

    describe '#inputs' do
        it 'uses the parent\'s inputs' do
            expect(subject.inputs).to eq(parent.inputs)
        end
    end

    describe '#trigger' do
        it 'triggers the event required to submit the element' do
            inputs = { 'param'  => 'The.Dude' }
            subject.update inputs

            called = false
            subject.with_browser do |browser|
                subject.browser = browser
                browser.load subject.page

                subject.trigger

                page = browser.to_page

                expect(subject.inputs).to eq(auditable_extract_parameters( page ))
                called = true
            end

            subject.auditor.browser_cluster.wait
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

            subject.auditor.browser_cluster.wait
            expect(called).to be_truthy

            called = false
            auditor.with_browser do |browser|
                browser.load subject.page
                expect(auditable_extract_parameters( browser.to_page )).to be_falsey

                transitions.each do |transition|
                    transition.play browser
                end

                expect(auditable_extract_parameters( browser.to_page )).to eq(inputs)
                called = true
            end
            auditor.browser_cluster.wait
            expect(called).to be_truthy
        end

        it 'updates nonces'
    end

end
