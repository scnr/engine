require 'spec_helper'

class AuditorTest < SCNR::Engine::Check::Base
    include SCNR::Engine::Check::Auditor

    self.shortname = Factory[:issue_data][:check][:shortname]

    def initialize( framework )
        @framework = framework
        load_page_from SCNR::Engine::Options.url

        http.update_cookies( page.cookie_jar )
    end

    def load_page_from( url )
        @page = SCNR::Engine::Page.from_url( url )

        framework.trainer.process page
        http.run

        @page
    end

    def self.info
        return @check_info if @check_info
        @check_info = Factory[:issue_data][:check].dup

        # Should be calculated by the auditor when it logs the issue.
        @check_info.delete :shortname

        @check_info[:issue] = {
            name:            "Check name \xE2\x9C\x93",
            description:     'Issue description',
            references:      {
                'Title' => 'http://some/url'
            },
            cwe:             1,
            severity:        SCNR::Engine::Severity::HIGH,
            remedy_guidance: 'How to fix the issue.',
            remedy_code:     'Sample code on how to fix the issue',
            tags:            %w(these are a few tags)
        }
        @check_info
    end

    def self.clear_info_cache
        super
        @check_info = nil
    end
end

describe SCNR::Engine::Check::Auditor do
    element_classes = [
        SCNR::Engine::Element::Link, SCNR::Engine::Element::Link::DOM,
        SCNR::Engine::Element::Form, SCNR::Engine::Element::Form::DOM,
        SCNR::Engine::Element::Cookie, SCNR::Engine::Element::Cookie::DOM,
        SCNR::Engine::Element::Header, SCNR::Engine::Element::LinkTemplate,
        SCNR::Engine::Element::LinkTemplate::DOM, SCNR::Engine::Element::JSON,
        SCNR::Engine::Element::XML, SCNR::Engine::Element::UIInput,
        SCNR::Engine::Element::UIInput::DOM, SCNR::Engine::Element::UIForm,
        SCNR::Engine::Element::UIForm::DOM
    ]

    before :each do
        enable_browser_cluster

        framework.reset

        SCNR::Engine::Options.url = url
        SCNR::Engine::Options.audit.elements SCNR::Engine::Page::ELEMENTS - [:link_templates]

        AuditorTest.clear_info_cache
    end

    after :all do
        $audit_timeout_called      = nil
        $audit_differential_called = nil
        $audit_taint_called        = nil
        $audit_called              = nil
    end

    let(:url) { SCNR::Engine::URI.normalize( web_server_url_for( :auditor ) ) }
    let(:framework) { SCNR::Engine::Framework.unsafe }
    let(:auditor) { AuditorTest.new( framework ) }
    let(:issue) { Factory[:issue] }
    let(:issue_data) { Factory[:issue_data].tap { |d| d.delete :check } }
    subject { auditor }

    describe '.has_timeout_candidates?' do
        it "delegates to #{SCNR::Engine::Element::Capabilities::Analyzable}.has_timeout_candidates?" do
            expect(SCNR::Engine::Element::Capabilities::Analyzable).to receive(:has_timeout_candidates?)
            described_class.has_timeout_candidates?
        end
    end

    describe '.timeout_audit_run' do
        it "delegates to #{SCNR::Engine::Element::Capabilities::Analyzable}.timeout_audit_run" do
            expect(SCNR::Engine::Element::Capabilities::Analyzable).to receive(:timeout_audit_run)
            described_class.timeout_audit_run
        end
    end

    describe '.calculate_signature_analysis_cost' do
        it "delegates to #{SCNR::Engine::Element::Capabilities::Analyzable::Signature}.calculate_cost"
    end

    describe '.calculate_differential_analysis_cost' do
        it "delegates to #{SCNR::Engine::Element::Capabilities::Analyzable::Differential}.calculate_cost"
    end

    describe '.calculate_timeout_analysis_cost' do
        it "delegates to #{SCNR::Engine::Element::Capabilities::Analyzable::Timeout}.calculate_cost"
    end

    describe '#preferred' do
        it 'returns an empty array' do
            expect(subject.preferred).to eq([])
        end
    end

    describe '#max_issues' do
        it 'returns the maximum amount of issues the auditor is allowed to log' do
            subject.class.info[:max_issues] = 1
            expect(subject.max_issues).to eq(1)
        end
    end

    describe '#increment_issue_counter' do
        it 'increments the issue counter' do
            i = subject.class.issue_counter
            subject.increment_issue_counter
            expect(subject.class.issue_counter).to eq(i + 1)
        end
    end

    describe '#issue_limit_reached?' do
        it 'returns false' do
            expect(subject.issue_limit_reached?).to be_falsey
        end

        context 'when the issue counter reaches the limit' do
            it 'returns true' do
                subject.class.info[:max_issues] = 1
                subject.increment_issue_counter
                expect(subject.issue_limit_reached?).to be_truthy
            end
        end
    end

    describe '#audited' do
        it 'marks the given task as audited' do
            subject.audited 'stuff'
            expect(subject.audited?( 'stuff' )).to be_truthy
        end
    end

    describe '.check?' do
        context 'when elements have been provided' do
            it 'restricts the check' do
                page = SCNR::Engine::Page.from_data( url: url, body: 'stuff',headers: [] )
                allow(page).to receive(:has_script?) { true }
                auditor.class.info[:elements] =
                    element_classes + [SCNR::Engine::Element::Body, SCNR::Engine::Element::GenericDOM]

                expect(auditor.class.check?( page, SCNR::Engine::Element::GenericDOM )).to be_truthy
                expect(auditor.class.check?( page, SCNR::Engine::Element::Body )).to be_truthy

                element_classes.each do |element|
                    expect(auditor.class.check?( page, element )).to be_falsey
                end

                expect(auditor.class.check?( page, element_classes )).to be_falsey
                expect(auditor.class.check?( page, element_classes + [SCNR::Engine::Element::Body] )).to be_truthy
            end
        end

        context 'Engine::Element::Body' do
            before(:each) { auditor.class.info[:elements] = SCNR::Engine::Element::Body }

            context 'and page with a non-empty body' do
                it 'returns true' do
                    p = SCNR::Engine::Page.from_data( url: url, body: 'stuff' )
                    expect(auditor.class.check?( p )).to be_truthy
                end
            end

            context 'and page with an empty body' do
                it 'returns false' do
                    p = SCNR::Engine::Page.from_data( url: url, body: '' )
                    expect(auditor.class.check?( p )).to be_falsey
                end
            end
        end

        context 'Engine::Element::GenericDOM' do
            before(:each) { auditor.class.info[:elements] = SCNR::Engine::Element::GenericDOM }
            let(:page) { SCNR::Engine::Page.from_data( url: url, body: 'stuff' ) }

            context 'and Page#has_script? is' do
                context 'true' do
                    it 'returns true' do
                        allow(page).to receive(:has_script?) { true }
                        expect(auditor.class.check?( page )).to be_truthy
                    end
                end

                context 'false' do
                    it 'returns false' do
                        allow(page).to receive(:has_script?) { false }
                        expect(auditor.class.check?( page )).to be_falsey
                    end
                end
            end
        end

        element_classes.each do |element|
            context "when #{SCNR::Engine::OptionGroups::Audit}##{element.type.to_s.gsub( '_dom', '')}? is" do
                let(:page) do
                    p = SCNR::Engine::Page.from_data(
                        url: url,
                        headers: [],
                        "#{element.type}s".gsub( '_dom', '').to_sym => [Factory[element.type]]
                    )
                    allow(p.dom).to receive(:depth) { 1 }
                    allow(p).to receive(:has_script?) { true }

                    (p.forms + p.cookies).each { |e| e.skip_dom = false }

                    p
                end
                before(:each) { auditor.class.info[:elements] = [element] }

                context 'true' do
                    before(:each) do
                        if element.type.to_s.start_with? 'link_template'
                            SCNR::Engine::Options.audit.link_templates =
                                Factory[element.type].template ||
                                    /input1\/(?<input1>\w+)\/input2\/(?<input2>\w+)/

                        else
                            SCNR::Engine::Options.audit.elements element.type
                        end
                    end

                    context "and the page contains #{element}" do
                        context 'and the check supports it' do
                            if element == SCNR::Engine::Element::Form::DOM ||
                                element == SCNR::Engine::Element::Cookie::DOM

                                context 'and Page::DOM#depth is' do
                                    context '0' do
                                        it 'returns false' do
                                            allow(page.dom).to receive(:depth) { 0 }
                                            expect(auditor.class.check?( page )).to be_falsey
                                        end
                                    end

                                    context '> 0' do
                                        it 'returns true' do
                                            allow(page.dom).to receive(:depth) { 1 }
                                            expect(auditor.class.check?( page )).to be_truthy
                                        end
                                    end
                                end

                                context 'and Page#has_script? is' do
                                    context 'true' do
                                        it 'returns true' do
                                            allow(page).to receive(:has_script?) { true }
                                            expect(auditor.class.check?( page )).to be_truthy
                                        end
                                    end

                                    context 'false' do
                                        it 'returns false' do
                                            allow(page).to receive(:has_script?) { false }
                                            expect(auditor.class.check?( page )).to be_falsey
                                        end
                                    end
                                end
                            elsif element == SCNR::Engine::Element::UIInput ||
                                         element == SCNR::Engine::Element::UIForm
                                it 'returns false' do
                                    expect(auditor.class.check?( page )).to be_falsey
                                end
                            else
                                it 'returns true' do
                                    expect(auditor.class.check?( page )).to be_truthy
                                end
                            end
                        end

                        (element_classes - [element]).each do |e|
                            context "and the check supports #{e}" do
                                if element == SCNR::Engine::Element::Cookie::DOM &&
                                    e == SCNR::Engine::Element::Cookie

                                    it 'returns true' do
                                        auditor.class.info[:elements] = e
                                        expect(auditor.class.check?( page )).to be_truthy
                                    end

                                elsif element == SCNR::Engine::Element::UIInput ||
                                    element == SCNR::Engine::Element::UIForm
                                    it 'returns false' do
                                        expect(auditor.class.check?( page )).to be_falsey
                                    end

                                elsif element == SCNR::Engine::Element::Cookie &&
                                        e == SCNR::Engine::Element::Cookie::DOM

                                    context 'and Page#has_script? is' do
                                        context 'true' do
                                            it 'returns true' do
                                                allow(page).to receive(:has_script?) { true }
                                                auditor.class.info[:elements] = e
                                                expect(auditor.class.check?( page )).to be_truthy
                                            end
                                        end

                                        context 'false' do
                                            it 'returns false' do
                                                allow(page).to receive(:has_script?) { false }
                                                auditor.class.info[:elements] = e
                                                expect(auditor.class.check?( page )).to be_falsey
                                            end
                                        end
                                    end

                                else
                                    if element == SCNR::Engine::Element::Form::DOM &&
                                        e == SCNR::Engine::Element::Form
                                        it 'returns true' do
                                            auditor.class.info[:elements] = e
                                            expect(auditor.class.check?( page )).to be_truthy
                                        end
                                    else
                                        it 'returns false' do
                                            auditor.class.info[:elements] = e
                                            expect(auditor.class.check?( page )).to be_falsey
                                        end
                                    end
                                end
                            end
                        end

                        [SCNR::Engine::Element::Path, SCNR::Engine::Element::Server, nil].each do |e|
                            context "and the check supports #{e ? e : 'everything'}" do
                                it 'returns true' do
                                    auditor.class.info[:elements] = e
                                    expect(auditor.class.check?( page )).to be_truthy
                                end
                            end
                        end
                    end
                end

                context 'false' do
                    before(:each) { SCNR::Engine::Options.audit.skip_elements element.type }

                    context "and the page contains #{element}" do
                        context "and the check only supports #{element}" do
                            it 'returns false' do
                                expect(auditor.class.check?( page )).to be_falsey
                            end
                        end

                        [SCNR::Engine::Element::Path, SCNR::Engine::Element::Server, nil].each do |e|
                            context "and the check supports #{e ? e : 'everything'}" do
                                it 'returns true' do
                                    auditor.class.info[:elements] = e
                                    expect(auditor.class.check?( page )).to be_truthy
                                end
                            end
                        end
                    end
                end
            end
        end
    end

    describe '#log_remote_file_if_exists' do
        it "delegates to #{SCNR::Engine::Element::Server}#log_remote_file_if_exists" do
            sent     = [:stuff, false, { blah: '1' }]
            received = nil
            b        = proc {}

            allow_any_instance_of(SCNR::Engine::Element::Server).to receive(:log_remote_file_if_exists) { |instance, args, &block| received = [args, block]}

            expect(subject.log_remote_file_if_exists( *sent, &b )).to eq(received)
        end
    end

    describe '#match_and_log' do
        it "delegates to #{SCNR::Engine::Element::Body}#match_and_log" do
            sent     = [:stuff]
            received = nil
            b        = proc {}

            allow_any_instance_of(SCNR::Engine::Element::Body).to receive(:match_and_log) { |instance, args, &block| received = [args, block]}

            expect(subject.match_and_log( *sent, &b )).to eq(received)
        end
    end

    describe '#log_remote_file' do
        let(:page) { SCNR::Engine::Page.from_url url }
        let(:issue) { SCNR::Engine::Data.issues.sort.last }
        let(:vector) { SCNR::Engine::Element::Server.new( page.url ) }

        it 'assigns the extra Issue options' do
            expect(subject.log_remote_file( page, false )).to be_trusted
            expect(subject.log_remote_file( page, false, trusted: false )).to_not be_trusted
        end

        context 'given a' do
            describe SCNR::Engine::Page do
                it 'logs it' do
                    subject.log_remote_file( page )
                    expect(issue.page).to eq(page)
                    expect(issue.vector).to eq(vector)
                end
            end

            describe SCNR::Engine::HTTP::Response do
                it "logs it as a #{SCNR::Engine::Page}" do
                    subject.log_remote_file( page.response )
                    expect(issue.page).to eq(page)
                    expect(issue.vector).to eq(vector)
                end
            end
        end
    end

    describe '#each_candidate_element' do
        before(:each) do
            SCNR::Engine::Options.audit.link_templates = /link-template\/input\/(?<input>.+)/
            auditor.load_page_from "#{url}/each_candidate_element"

            auditor.page.jsons     = [Factory[:json]]
            auditor.page.xmls      = [Factory[:xml]]
            auditor.page.ui_inputs = [Factory[:ui_input]]
            auditor.page.ui_forms  = [Factory[:ui_form]]

            auditor.class.info[:elements].clear
        end

        it 'sets the auditor' do
            called = false
            auditor.each_candidate_element do |element|
                expect(element.auditor).to eq(auditor)
                called = true
            end
            expect(called).to be_truthy
        end

        context 'when #skip?' do
            context 'returns false' do
                it 'skips the element'
            end

            context 'returns true' do
                it 'includes the element'
            end
        end

        it 'provides the types of elements specified by the check' do
            auditor.class.info[:elements] = [SCNR::Engine::Link, SCNR::Engine::Form]

            elements = []
            auditor.each_candidate_element do |element|
                elements << element
            end

            expect(auditor.class.elements).to eq([SCNR::Engine::Link, SCNR::Engine::Form])
            expect(elements).to eq((auditor.page.links | auditor.page.forms).
                select { |e| e.inputs.any? })
        end

        context 'and no types are specified by the check' do
            it 'provides all types of elements but :ui_inputs and :ui_forms'do
                expected_elements = SCNR::Engine::Page::ELEMENTS.dup
                expected_elements.delete :ui_inputs
                expected_elements.delete :ui_forms

                elements = []
                auditor.each_candidate_element do |element|
                    elements << element
                end

                expect(elements.map { |e| "#{e.type}s".to_sym }.uniq.sort).to eq(expected_elements.sort)
                expect(elements).to be_same_array_as((auditor.page.elements).
                    select { |e| ![:ui_input, :ui_form].include?( e.type ) && e.inputs.any? })
            end
        end
    end

    describe '#each_candidate_dom_element' do
        before(:each) do
            SCNR::Engine::Options.audit.link_templates = /dom-link-template\/input\/(?<input>.+)/
            auditor.load_page_from "#{url}each_candidate_dom_element"

            auditor.page.ui_inputs = [Factory[:ui_input]]
            auditor.page.ui_forms  = [Factory[:ui_form]]
        end

        it 'sets the auditor' do
            auditor.class.info[:elements].clear

            called = false
            auditor.each_candidate_dom_element do |element|
                expect(element.auditor).to eq(auditor)
                called = true
            end
            expect(called).to be_truthy
        end

        context 'when #skip?' do
            context 'returns false' do
                it 'skips the element'
            end

            context 'returns true' do
                it 'includes the element'
            end
        end

        it 'provides the types of elements specified by the check' do
            auditor.class.info[:elements] = [SCNR::Engine::Link::DOM]
            expect(auditor.class.elements).to eq([SCNR::Engine::Link::DOM])

            elements = []
            auditor.each_candidate_dom_element do |element|
                elements << element
            end

            expect(elements).to eq(auditor.page.links.map(&:dom).compact)
        end

        context 'and no types are specified by the check' do
            it 'provides all types of elements'do
                auditor.class.info[:elements].clear

                (auditor.page.cookies + auditor.page.forms).each { |e| e.skip_dom = false }


                elements = []
                auditor.each_candidate_dom_element do |element|
                    elements << element
                end

                expect(elements).to eq(
                    (auditor.page.links.select { |l| l.dom } |
                        auditor.page.forms | auditor.page.cookies |
                        auditor.page.link_templates | auditor.page.ui_inputs |
                        auditor.page.ui_forms).map(&:dom)
                )
            end
        end
    end

    describe '#with_browser_cluster' do
        context 'when a browser cluster is' do
            context 'available' do
                it 'passes it to the given block' do
                    worker = nil

                    expect(auditor.with_browser_cluster do |cluster|
                        worker = cluster
                    end).to be_truthy

                    expect(worker).to eq(framework.browser_cluster)
                end
            end
        end
    end

    describe '#with_browser' do
        context 'when a browser cluster is' do
            context 'available' do
                it 'passes a BrowserCluster::Worker to the given block' do
                    worker = nil

                    expect(auditor.with_browser (proc_to_method do |browser|
                        worker = browser
                    end)).to be_truthy
                    framework.browser_cluster.wait

                    expect(worker).to be_kind_of SCNR::Engine::BrowserCluster::Worker
                end
            end
        end
    end

    describe '#compatible_sinks?' do
        context 'when the elements has no sinks' do
            it 'returns true'
        end

        context 'when the check does not care about sinks' do
            it 'returns true'
        end

        context 'when the element has sinks' do
            context 'which have been marked as #override!' do
                it 'returns true'
            end

            context 'which have not been traced' do
                context 'but have been marked as #override!' do
                    it 'returns true'
                end

                context 'but have not been marked as #override!' do
                    it 'returns false'
                end
            end

            context 'which have been traced' do
                context 'and are supported by the check' do
                    it 'returns true'
                end

                context 'but are not supported by the check' do
                    it 'returns false'
                end
            end
        end
    end

    describe '#duplicate_check?' do
        context 'when a we have already logged the same element' do
            it 'returns true'
        end

        context 'when a preferred auditor has already logged the same element' do
            it 'returns true'
        end
    end

    describe '#skip?' do
        context 'when checking a form mutation' do
            it 'checks sink compatibility'

            context 'with original values' do
                it 'does not check sink compatibility'
            end

            context 'with sample values' do
                it 'does not check sink compatibility'
            end
        end

        context 'when #compatible_sinks?' do
            context 'returns false' do
                it 'returns true' do
                    allow(auditor).to receive(:compatible_sinks?) { false }
                    expect(auditor.skip?( auditor.page.elements.first )).to be_truthy
                end
            end

            context 'returns true' do
                it 'returns false' do
                    allow(auditor).to receive(:compatible_sinks?) { true }
                    expect(auditor.skip?( auditor.page.elements.first )).to be_falsey
                end
            end
        end

        context 'when there is no Engine::Page#element_audit_whitelist' do
            it 'returns false' do
                expect(auditor.page.element_audit_whitelist).to be_empty
                expect(auditor.skip?( auditor.page.elements.first )).to be_falsey
            end
        end

        context 'when there is Engine::Page#element_audit_whitelist' do
            context 'and the element is in it' do
                it 'returns false' do
                    auditor.page.update_element_audit_whitelist auditor.page.elements.first
                    expect(auditor.skip?( auditor.page.elements.first )).to be_falsey
                end
            end

            context 'and the element is not in it' do
                it 'returns true' do
                    auditor.page.update_element_audit_whitelist auditor.page.elements.first
                    expect(auditor.skip?( auditor.page.elements.last )).to be_truthy
                end
            end
        end

        context 'when #duplicate_check?' do
            context 'returns false' do
                it 'returns false' do
                    allow(auditor).to receive(:duplicate_check?) { false }
                    expect(auditor.skip?( auditor.page.elements.first )).to be_falsey
                end
            end

            context 'returns true' do
                it 'returns true' do
                    allow(auditor).to receive(:duplicate_check?) { true }
                    expect(auditor.skip?( auditor.page.elements.first )).to be_truthy
                end
            end
        end
    end

    describe '#create_issue' do
        it 'creates an issue' do
            expect(
                auditor.class.create_issue(
                    proof: issue.proof,
                    vector: issue.vector,
                    referring_page: issue.referring_page
                )
            ).to eq(issue)
        end
    end

    describe '.log_issue' do
        it 'logs an issue' do
            expect(SCNR::Engine::Data.issues).to be_empty
            auditor.class.log_issue( issue )

            logged_issue = SCNR::Engine::Data.issues.sort.first
            expect( logged_issue.digest ).to eq issue.digest
        end

        it 'assigns a #referring_page' do
            auditor.log_issue( issue )

            logged_issue = SCNR::Engine::Data.issues.sort.first
            expect(logged_issue.referring_page).to eq(issue.referring_page)
        end

        it 'returns the issue' do
            expect(auditor.log_issue( issue )).to be_kind_of SCNR::Engine::Issue
        end

        context 'when #issue_limit_reached?' do
            it 'does not log the issue' do
                allow(auditor.class).to receive(:issue_limit_reached?) { true }

                expect(auditor.class.log_issue( issue_data )).to be_falsey
                expect(SCNR::Engine::Data.issues).to be_empty
            end
        end
    end

    describe '#log_issue' do
        it 'forwards options to .log_issue' do
            expect(auditor.class).to receive(:log_issue).with( issue )
            auditor.log_issue( issue )
        end

        it 'assigns a #referring_page' do
            auditor.log_issue( issue )

            logged_issue = SCNR::Engine::Data.issues.sort.first
            expect(logged_issue.referring_page).to eq(issue.referring_page)
        end
    end

    describe '.log' do
        let(:issue_data) do
            d = super()

            d[:page].response.url = SCNR::Engine::Options.url
            d.merge( page: d[:page] )

            d
        end

        it 'preserves the given remarks' do
            auditor.class.log( issue_data )

            logged_issue = SCNR::Engine::Data.issues.sort.first
            expect(logged_issue.remarks.first).to be_any
        end

        it 'returns the issue' do
            expect(auditor.class.log( issue_data )).to be_kind_of SCNR::Engine::Issue
        end

        context 'when given a page' do
            after { framework.http.run }

            it 'includes response data' do
                auditor.class.log( issue_data )
                expect(SCNR::Engine::Data.issues.sort.first.response).to eq(
                    issue_data[:page].response
                )
            end

            it 'includes request data' do
                auditor.class.log( issue_data )
                expect(SCNR::Engine::Data.issues.sort.first.request).to eq(
                    issue_data[:page].request
                )
            end
        end

        context 'when not given a page' do
            it 'uses the referring page' do
                issue_data[:referring_page].response.url = SCNR::Engine::Options.url
                auditor.class.log( issue_data )

                issue = SCNR::Engine::Data.issues.sort.first

                expect(issue.page.body).to eq(issue_data[:referring_page].body)
                expect(issue.response).to eq(issue_data[:referring_page].response)
                expect(issue.request).to eq(issue_data[:referring_page].request)
            end
        end

        context 'when :referring page has been set' do
            it 'uses it to set the Issue#referring_page' do
                i = auditor.class.log( issue_data )
                expect(i.referring_page).to eq issue_data[:referring_page]
            end
        end

        context 'when no :referring page has been set' do
            it 'uses Element#page' do
                issue_data[:vector].page = issue_data.delete( :referring_page )

                i = auditor.class.log( issue_data )
                expect(i.referring_page).to eq issue_data[:vector].page
            end
        end

        context 'when no referring page data are available' do
            it 'raises ArgumentError' do
                expect do
                    issue_data[:vector].page    = nil
                    issue_data[:referring_page] = nil
                    issue_data[:page]           = nil
                    issue_data[:response]       = nil

                    auditor.class.log( issue_data )
                end.to raise_error ArgumentError
            end
        end

        context 'when the resource is out of scope' do
            let(:issue_data) do
                d = super()

                d[:page].response.url = 'http://stuff/'
                d.merge( page: d[:page] )

                d
            end

            it 'returns nil' do
                expect(auditor.log( issue_data )).to be_nil
            end

            it 'does not log the issue' do
                auditor.log( issue_data )
                expect(issues).to be_empty
            end

            context 'and the host includes the seed' do
                let(:issue_data) do
                    d = super()

                    d[:page].response.url = "http://#{SCNR::Engine::Utilities.random_seed}.com/"
                    d.merge( page: d[:page] )

                    d
                end

                it 'does not log the issue' do
                    auditor.log( issue_data )
                    expect(issues).to be_any
                end
            end
        end
    end

    describe '#log' do
        let(:issue_data) do
            d = super()

            d[:page].response.url = SCNR::Engine::Options.url
            d.merge( page: d[:page] )

            d
        end

        it 'forwards options to .log_issue' do
            expect(auditor.class).to receive(:log).with(
                issue_data.merge( referring_page: auditor.page )
            )
            auditor.log( issue_data )
        end
    end

    describe '#audit' do
        let(:seed) { 'my_seed' }
        let(:default_input_value) { 'blah' }

        context 'when called with no options' do
            it 'uses the defaults' do
                auditor.load_page_from( url + '/link' )
                auditor.audit( seed )
                framework.http.run
                expect(SCNR::Engine::Data.issues.size).to eq(1)
            end
        end

        context 'when the payloads are per platform' do
            it 'assigns the platform of the payload to the issue' do
                auditor.load_page_from( url + '/link' )
                auditor.audit( { unix: seed }, substring: seed )
                framework.http.run
                expect(SCNR::Engine::Data.issues.size).to eq(1)
                issue = SCNR::Engine::Data.issues.sort.first
                expect(issue.platform_name).to eq(:unix)
                expect(issue.platform_type).to eq(:os)
            end
        end

        context 'when called with a block' do
            it "delegates to #{SCNR::Engine::Element::Capabilities::Auditable}#audit" do
                auditor.load_page_from( url + '/link' )

                $audit_called = []
                auditor.page.elements.each do |element|
                    element.class.class_eval do
                        def audit( *args, &block )
                            $audit_called << self.class if $audit_called
                            super( *args, &block )
                        end
                    end
                end

                auditor.audit( seed ){}
                expect($audit_called).to eq(auditor.class.elements)
            end
        end

        context 'when called without a block' do
            it 'delegates to #audit_signature' do
                opts = { stuff: :here }

                expect(auditor).to receive(:audit_signature).with( seed, opts )
                auditor.audit( seed, opts )
            end
        end

        context 'when called with options' do
            describe ':train' do
                context 'default' do
                    it 'parses the responses of forms submitted with their default values and feed any new elements back to the framework to be audited' do
                        # page feedback queue
                        pages = [ SCNR::Engine::Page.from_url( url + '/train/default' ) ]

                        framework.trainer.setup
                        # feed the new pages/elements back to the queue
                        framework.trainer.on_new_page { |p| pages << p }
                        framework.trainer.process pages.first
                        framework.http.run

                        # feed the new pages/elements back to the queue
                        framework.trainer.on_new_page { |p| pages << p }

                        vector = nil
                        # audit until no more new elements appear
                        while (page = pages.pop)
                            framework.trainer.process page
                            framework.http.run

                            auditor = Auditor.new( page, framework )
                            auditor.audit( seed ) do |response, mutation|
                                next if !response.body.include?( seed ) ||
                                    mutation.affected_input_name != 'you_made_it'

                                vector = mutation.affected_input_name
                            end

                            # run audit requests
                            framework.http.run

                            framework.trainer.wait
                        end

                        expect(vector).to eq 'you_made_it'
                    end
                end

                context 'true' do
                    it 'parses all responses and feed any new elements back to the framework to be audited' do
                        # page feedback queue
                        pages = [ SCNR::Engine::Page.from_url( url + '/train/true' ) ]

                        framework.trainer.setup
                        # feed the new pages/elements back to the queue
                        framework.trainer.on_new_page { |p| pages << p }
                        framework.trainer.process pages.first
                        framework.http.run

                        vector = nil
                        # audit until no more new elements appear
                        while (page = pages.pop)
                            framework.trainer.process page
                            framework.http.run

                            auditor = SCNR::Engine::Check::Base.new( page, framework )
                            auditor.audit( seed, submit: { train: true } ) do |response, mutation|
                                next if !response.body.include?( seed ) ||
                                    mutation.affected_input_name != 'you_made_it'

                                vector = mutation.affected_input_name
                            end
                            # run audit requests
                            framework.http.run

                            framework.trainer.wait
                        end

                        expect(vector).to eq 'you_made_it'
                    end
                end

                context 'false' do
                    it 'skips analysis' do
                        # page feedback queue
                        page = SCNR::Engine::Page.from_url( url + '/train/true' )

                        # initial page
                        framework.trainer.setup

                        updated_pages = []
                        # feed the new pages/elements back to the queue
                        framework.trainer.on_new_page { |p| updated_pages << p }

                        framework.trainer.process page
                        framework.http.run

                        auditor = SCNR::Engine::Check::Base.new( page, framework )
                        auditor.audit( seed, submit: { train: false } )

                        framework.http.run
                        framework.trainer.wait

                        expect(updated_pages).to be_empty
                    end
                end
            end
        end
    end

    describe '#audit_signature' do
        it "delegates to #{SCNR::Engine::Element::Capabilities::Analyzable::Signature}#signature_analysis" do
            auditor.load_page_from( url + '/link' )

            $audit_signature_called = []
            auditor.page.elements.each do |element|
                element.class.class_eval do
                    def signature_analysis( *args, &block )
                        $audit_signature_called << self.class if $audit_signature_called
                        super( *args, &block )
                    end
                end
            end

            auditor.audit_signature( 'seed' )
            expect($audit_signature_called).to eq(auditor.class.elements)
        end
    end

    describe '#audit_differential' do
        it "delegates to #{SCNR::Engine::Element::Capabilities::Analyzable::Differential}#differential_analysis" do
            auditor.load_page_from( url + '/link' )

            $audit_differential_called = []
            auditor.page.elements.each do |element|
                element.class.class_eval do
                    def differential_analysis( *args, &block )
                        $audit_differential_called << self.class if $audit_differential_called
                        super( *args, &block )
                    end
                end
            end

            auditor.audit_differential( { false: '0', pairs: { '1' => '2' } } )
            expect($audit_differential_called).to eq(auditor.class.elements)
        end
    end

    describe '#audit_timeout' do
        it "delegates to #{SCNR::Engine::Element::Capabilities::Analyzable::Timeout}#timeout_analysis" do
            auditor.load_page_from( url + '/link' )

            $audit_timeout_called = []
            auditor.page.elements.each do |element|
                element.class.class_eval do
                    def timeout_analysis( *args, &block )
                        $audit_timeout_called << self.class if $audit_timeout_called
                        super( *args, &block )
                    end
                end
            end

            auditor.audit_timeout( 'seed', timeout: 1 )
            expect($audit_timeout_called).to eq(auditor.class.elements)
        end
    end

    describe '#trace_taint' do
        context 'when tracing the data-flow' do
            let(:taint) { SCNR::Engine::Utilities.generate_token }
            let(:url) do
                SCNR::Engine::Utilities.normalize_url( web_server_url_for( :taint_tracer ) ) +
                    "/data_trace/user-defined-global-functions?taint=#{taint}"
            end

            context 'and the resource is a' do
                context 'String' do
                    it 'loads the URL and traces the taint' do
                        pages = []
                        auditor.trace_taint( url, {taint: taint}, (proc_to_method do |result|
                            pages << result.page
                            false
                        end))
                        auditor.browser_cluster.wait

                        browser_cluster_job_taint_tracer_data_flow_check_pages  pages
                    end
                end

                context 'Engine::HTTP::Response' do
                    it 'loads it and traces the taint' do
                        pages = []

                        auditor.trace_taint( SCNR::Engine::HTTP::Client.get( url, mode: :sync ),
                                              {taint: taint}, (proc_to_method do |result|
                            pages << result.page
                            false
                        end))
                        auditor.browser_cluster.wait

                        browser_cluster_job_taint_tracer_data_flow_check_pages  pages
                    end
                end

                context 'Engine::Page' do
                    it 'loads it and traces the taint' do
                        pages = []

                        auditor.trace_taint( SCNR::Engine::Page.from_url( url ),
                                              {taint: taint}, (proc_to_method do |result|
                            pages << result.page
                            false
                        end))
                        auditor.browser_cluster.wait

                        browser_cluster_job_taint_tracer_data_flow_check_pages  pages
                    end
                end
            end

            context 'and requires a custom taint injector' do
                let(:injector) { "location.hash = #{taint.inspect}" }
                let(:url) do
                    SCNR::Engine::Utilities.normalize_url( web_server_url_for( :taint_tracer ) ) +
                        'needs-injector'
                end

                context 'and the resource is a' do
                    context 'String' do
                        it 'loads the URL and traces the taint' do
                            pages = []
                            auditor.trace_taint( url,
                                                  {taint: taint,
                                                  injector: injector}, (proc_to_method do |result|
                                pages << result.page
                                false
                            end))
                            auditor.browser_cluster.wait

                            browser_cluster_job_taint_tracer_data_flow_with_injector_check_pages  pages
                        end
                    end

                    context 'Engine::HTTP::Response' do
                        it 'loads it and traces the taint' do
                            pages = []
                            auditor.trace_taint( SCNR::Engine::HTTP::Client.get( url, mode: :sync ),
                                                  {taint: taint,
                                                  injector: injector}, (proc_to_method do |result|
                                pages << result.page
                                false
                            end))
                            auditor.browser_cluster.wait

                            browser_cluster_job_taint_tracer_data_flow_with_injector_check_pages  pages
                        end
                    end

                    context 'Engine::Page' do
                        it 'loads it and traces the taint' do
                            pages = []
                            auditor.trace_taint( SCNR::Engine::Page.from_url( url ),
                                                  {taint: taint,
                                                  injector: injector}, (proc_to_method do |result|
                                pages << result.page
                                false
                            end))
                            auditor.browser_cluster.wait

                            browser_cluster_job_taint_tracer_data_flow_with_injector_check_pages  pages
                        end
                    end
                end
            end
        end

        context 'when tracing the execution-flow' do
            let(:url) do
                SCNR::Engine::Utilities.normalize_url( web_server_url_for( :taint_tracer ) )
            end
            let(:stub_url) do
                "#{url}debug?input=#{auditor.browser_cluster.javascript_token}TaintTracer.log_execution_flow_sink()"
            end

            context 'and the resource is a' do
                context 'String' do
                    it 'loads the URL and traces the taint' do
                        pages = []
                        auditor.trace_taint( stub_url, (proc_to_method do |result|
                            pages << result.page
                            false
                        end))
                        auditor.browser_cluster.wait

                        browser_cluster_job_taint_tracer_execution_flow_check_pages pages
                    end
                end

                context 'Engine::HTTP::Response' do
                    it 'loads it and traces the taint' do
                        pages = []
                        auditor.trace_taint( SCNR::Engine::HTTP::Client.get( stub_url, mode: :sync ), (proc_to_method do |result|
                            pages << result.page
                            false
                        end))
                        auditor.browser_cluster.wait

                        browser_cluster_job_taint_tracer_execution_flow_check_pages pages
                    end
                end

                context 'Engine::Page' do
                    it 'loads it and traces the taint' do
                        pages = []
                        auditor.trace_taint( SCNR::Engine::Page.from_url( stub_url ), (proc_to_method do |result|
                            pages << result.page
                            false
                        end))
                        auditor.browser_cluster.wait

                        browser_cluster_job_taint_tracer_execution_flow_check_pages pages
                    end
                end
            end
        end

        context 'when the block returns' do
            let(:url) do
                SCNR::Engine::Utilities.normalize_url( web_server_url_for( :taint_tracer ) )
            end
            let(:stub_url) do
                "#{url}debug?input=#{auditor.browser_cluster.javascript_token}TaintTracer.log_execution_flow_sink()"
            end

            context 'true' do
                it 'marks the job as done' do
                    skip

                    calls = 0
                    auditor.trace_taint( url, (proc_to_method do
                        calls += 1
                        true
                    end))
                    auditor.browser_cluster.wait
                    expect(calls).to eq(1)
                end
            end

            context 'false' do
                it 'allows the job to continue' do
                    calls = 0

                    auditor.trace_taint( stub_url, (proc_to_method do
                        calls += 1
                        false
                    end))
                    auditor.browser_cluster.wait
                    expect(calls).to be > 0
                end
            end
        end
    end
end
