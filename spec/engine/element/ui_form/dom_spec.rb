require 'spec_helper'

describe SCNR::Engine::Element::UIForm::DOM do
    inputs = { 'my-input' => 'stuff' }

    it_should_behave_like 'element_dom'

    it_should_behave_like 'with_node'
    it_should_behave_like 'with_auditor'
    it_should_behave_like 'with_sinks'

    it_should_behave_like 'with_locator'
    it_should_behave_like 'submittable_dom'
    it_should_behave_like 'inputtable_dom', inputs: inputs
    it_should_behave_like 'mutable_dom',    inputs: inputs
    it_should_behave_like 'auditable_dom'

    def run
        auditor.browser_cluster.wait
    end

    def auditable_extract_parameters( page )
        {
            'my-input' => Nokogiri::HTML(page.body).css('#container').text.strip
        }
    end

    def element( inputs )
        e = SCNR::Engine::Element::UIForm.new(
            method:       'click',
            action:       page.url,
            source:       '<button id="insert">Insert into DOM</button>',
            inputs:       inputs,
            opening_tags: {
                'my-input' => "<input id=\"my-input\" type=\"text\" value=\"stuff\">"
            }
        ).dom
        e.page    = page
        e.auditor = auditor
        e
    end

    before(:each) do
        enable_browser_cluster
        SCNR::Engine::Framework.unsafe.reset
    end

    subject { element( inputs ) }
    let(:page) { SCNR::Engine::Page.from_url( url ) }
    let(:framework) { SCNR::Engine::Framework.unsafe }
    let(:auditor) { Auditor.new( page ) }
    let(:parent) { subject.parent }
    let(:url) { web_server_url_for( :ui_form_dom ) }
    let(:inputtable) { element( inputs ) }

    let(:with_sinks) do
        e = SCNR::Engine::Element::UIForm.new(
            method:       'click',
            action:       "#{url}/sinks/body",
            source:       '<button id="insert">Insert into DOM</button>',
            inputs:       {
                'active' => 'value1',
                'blind'  => 'value2'
            },
            opening_tags: {
                'active' => "<input id=\"active\" type=\"text\" value=\"value1\">",
                'blind'  => "<input id=\"blind\" type=\"text\" value=\"value2\">"
            }
        ).dom
        e.page    = SCNR::Engine::Page.from_url( e.action )
        e.auditor = Auditor.new( e.page )
        e
    end
    let(:with_sinks_in_body) do
        with_sinks
    end
    let(:with_sinks_blind) do
        e = SCNR::Engine::Element::UIForm.new(
            method:       'click',
            action:       "#{url}/sinks/blind",
            source:       '<button id="insert">Insert into DOM</button>',
            inputs:       {
                'active' => 'value1',
                'blind'  => 'value2'
            },
            opening_tags: {
                'active' => "<input id=\"active\" type=\"text\" value=\"value1\">",
                'blind'  => "<input id=\"blind\" type=\"text\" value=\"value2\">"
            }
        ).dom
        e.page    = SCNR::Engine::Page.from_url( e.action )
        e.auditor = Auditor.new( e.page )
        e
    end
    let(:with_sinks_active) do
        e = SCNR::Engine::Element::UIForm.new(
            method:       'click',
            action:       "#{url}/sinks/active",
            source:       '<button id="insert">Insert into DOM</button>',
            inputs:       {
                'active' => 'value1',
                'blind'  => 'value2'
            },
            opening_tags: {
                'active' => "<input id=\"active\" type=\"text\" value=\"value1\">",
                'blind'  => "<input id=\"blind\" type=\"text\" value=\"value2\">"
            }
        ).dom
        e.page    = SCNR::Engine::Page.from_url( e.action )
        e.auditor = Auditor.new( e.page )
        e
    end

    describe '#type' do
        it 'returns :ui_form_dom' do
            expect(subject.type).to eq(:ui_form_dom)
        end
    end

    describe '.type' do
        it 'returns :ui_form_dom' do
            expect(described_class.type).to eq(:ui_form_dom)
        end
    end

    describe '#parent' do
        it 'returns the parent element' do
            expect(subject.parent).to be_kind_of SCNR::Engine::Element::UIForm
        end
    end

    describe '#inputs' do
        it 'returns the parent inputs' do
            expect(subject.inputs).to eq subject.parent.inputs
        end
    end

    describe '#trigger' do
        let(:new_inputs) { { subject.inputs.keys.first  => 'The.Dude' } }

        it 'triggers the event required to submit the element' do
            subject.update new_inputs

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
            subject.update new_inputs

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
                expect(auditable_extract_parameters( browser.to_page ).values.first).to eq ''

                transitions.each do |transition|
                    transition.play browser
                end

                expect(auditable_extract_parameters( browser.to_page )).to eq(new_inputs)
                called = true
            end
            auditor.browser_cluster.wait
            expect(called).to be_truthy
        end
    end

    describe '#coverage_id' do
        let(:action) { page.url }
        let(:method) { 'click' }
        let(:source) { '<button id="insert">Insert into DOM</button>' }
        let(:opening_tags) { {
            'my-input' => "<input id=\"my-input\" type=\"text\" value=\"stuff\">"
        } }
        let(:options) do
            {
                method:       method,
                action:       action,
                source:       source,
                inputs:       inputs,
                opening_tags: opening_tags
            }
        end

        def get_element( o = {} )
            SCNR::Engine::Element::UIForm.new( options.merge( o ) ).dom
        end

        it 'takes the #method into consideration' do
            s1 = get_element
            s2 = get_element( method: 'mouseover' )

            expect(s1.coverage_id).to_not eq s2.coverage_id
        end

        it 'takes the #locator into consideration' do
            s1 = get_element
            s2 = get_element( source: '<button id="insert2">Insert into DOM</button>' )

            expect(s1.coverage_id).to_not eq s2.coverage_id
        end
    end

    describe '#id' do
        let(:action) { page.url }
        let(:method) { 'click' }
        let(:source) { '<button id="insert">Insert into DOM</button>' }
        let(:opening_tags) { {
            'my-input' => "<input id=\"my-input\" type=\"text\" value=\"stuff\">"
        } }
        let(:options) do
            {
                method:       method,
                action:       action,
                source:       source,
                inputs:       inputs,
                opening_tags: opening_tags
            }
        end

        def get_element( o = {} )
            SCNR::Engine::Element::UIForm.new( options.merge( o ) ).dom
        end

        it 'takes the #method into consideration' do
            s1 = get_element
            s2 = get_element( method: 'mouseover' )

            expect(s1.id).to_not eq s2.id
        end

        it 'takes the #locator into consideration' do
            s1 = get_element
            s2 = get_element( source: '<button id="insert2">Insert into DOM</button>' )

            expect(s1.id).to_not eq s2.id
        end
    end
end
