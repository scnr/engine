require 'spec_helper'

describe SCNR::Engine::Framework::Parts::Audit do
    include_examples 'framework'

    describe 'Engine::OptionGroups::Scope' do
        describe '#exclude_binaries' do
            it 'excludes binary pages from the scan' do
                audited = []
                SCNR::Engine::Framework.new do |f|
                    f.options.url = url
                    f.options.scope.restrict_paths << url + '/binary'
                    f.options.audit.elements :links, :forms, :cookies
                    f.checks.load :signature

                    f.on_page_audit { |p| audited << p.url }
                    f.run
                end
                expect(audited.sort).to eq([url + '/binary'].sort)

                audited = []
                SCNR::Engine::Framework.new do |f|
                    f.options.url = url
                    f.options.scope.restrict_paths << url + '/binary'
                    f.options.scope.exclude_binaries = true
                    f.checks.load :signature

                    f.on_page_audit { |p| audited << p.url }
                    f.run
                end
                expect(audited).to be_empty
            end
        end

        describe '#extend_paths' do
            it 'extends the crawl scope' do
                SCNR::Engine::Framework.new do |f|
                    f.options.url = "#{url}/elem_combo"
                    f.options.scope.extend_paths = %w(/some/stuff /more/stuff)
                    f.options.audit.elements :links, :forms, :cookies
                    f.checks.load :signature

                    f.run

                    expect(f.report.sitemap).to include "#{url}/some/stuff"
                    expect(f.report.sitemap).to include "#{url}/more/stuff"
                    expect(f.report.sitemap.size).to be > 3
                end
            end
        end

        describe '#restrict_paths' do
            it 'serves as a replacement to crawling' do
                SCNR::Engine::Framework.new do |f|
                    f.options.url = "#{url}/elem_combo"
                    f.options.scope.restrict_paths = %w(/log_remote_file_if_exists/true)
                    f.options.audit.elements :links, :forms, :cookies
                    f.checks.load :signature

                    f.run

                    sitemap = f.report.sitemap.map { |u, _| u.split( '?' ).first }
                    expect(sitemap.sort.uniq).to eq(f.options.scope.restrict_paths.
                        map { |p| f.to_absolute( p ) }.sort)
                end
            end
        end
    end

    context 'when unable to get a response for the given URL' do
        context 'due to a network error' do
            it 'returns an empty sitemap and have failures' do
                SCNR::Engine::Options.url = 'http://blahaha'
                SCNR::Engine::Options.scope.restrict_paths = [SCNR::Engine::Options.url]

                subject.checks.load :signature
                subject.run
                expect(subject.failures).to be_any
            end
        end

        context 'due to a server error' do
            it 'returns an empty sitemap and have failures' do
                SCNR::Engine::Options.url = f_url + '/fail'
                SCNR::Engine::Options.scope.restrict_paths = [SCNR::Engine::Options.url]

                subject.checks.load :signature
                subject.run
                expect(subject.failures).to be_any
            end
        end

        it "retries #{SCNR::Engine::Framework::PAGE_MAX_TRIES} times" do
            SCNR::Engine::Options.url = f_url + '/fail_4_times'
            SCNR::Engine::Options.scope.restrict_paths = [SCNR::Engine::Options.url]

            subject.checks.load :signature
            subject.run
            expect(subject.failures).to be_empty
        end
    end

    describe '#http' do
        it 'provides access to the HTTP interface' do
            expect(subject.http.is_a?( SCNR::Engine::HTTP::Client )).to be_truthy
        end
    end

    describe '#failures' do
        context 'when there are no failed requests' do
            it 'returns an empty array' do
                SCNR::Engine::Options.url = f_url
                SCNR::Engine::Options.scope.restrict_paths = [SCNR::Engine::Options.url]

                subject.checks.load :signature
                subject.run
                expect(subject.failures).to be_empty
            end
        end
        context 'when there are failed requests' do
            it 'returns an array containing the failed URLs' do
                SCNR::Engine::Options.url = f_url + '/fail'
                SCNR::Engine::Options.scope.restrict_paths = [SCNR::Engine::Options.url]

                subject.checks.load :signature
                subject.run
                expect(subject.failures).to be_any
            end
        end
    end

    describe '#on_page_audit' do
        it 'calls the given block before each page is audited' do
            ok = false
            SCNR::Engine::Framework.new do |f|
                f.options.url = url
                f.on_page_audit { ok = true }

                f.audit_page SCNR::Engine::Page.from_url( url + '/link' )
            end
            expect(ok).to be_truthy
        end
    end

    describe '#after_page_audit' do
        it 'calls the given block before each page is audited' do
            ok = false
            SCNR::Engine::Framework.new do |f|
                f.options.url = url
                f.after_page_audit { ok = true }

                f.audit_page SCNR::Engine::Page.from_url( url + '/link' )
            end
            expect(ok).to be_truthy
        end
    end

    describe '#audit_page' do
        it 'updates the #sitemap with the DOM URL' do
            subject.options.audit.elements :links, :forms, :cookies
            subject.checks.load :signature

            expect(subject.sitemap).to be_empty

            page = SCNR::Engine::Page.from_url( url + '/link' )
            page.dom.url = url + '/link/#/stuff'

            subject.audit_page page
            expect(subject.sitemap).to include url + '/link/#/stuff'
        end

        it "runs checks without platforms before ones with platforms" do
            SCNR::Engine::Options.paths.checks = fixtures_path + '/checks/'

            SCNR::Engine::Framework.new do |f|
                f.checks.load_all

                page = SCNR::Engine::Page.from_url( url + '/link' )

                responses = []
                f.http.on_complete do |response|
                    responses << response.url
                end

                f.audit_page page

                expect(responses.sort).to eq(
                    %w(http://localhost/test3 http://localhost/test
                        http://localhost/test2).sort
                )

                expect(responses.last).to eq 'http://localhost/test2'
            end
        end

        context 'when checks were' do
            context 'ran against the page' do
                it 'returns true' do
                    subject.checks.load :signature
                    expect(subject.audit_page( SCNR::Engine::Page.from_url( url + '/link' ) )).to be_truthy
                end
            end

            context 'not ran against the page' do
                it 'returns false' do
                    expect(subject.audit_page( SCNR::Engine::Page.from_url( url + '/link' ) )).to be_falsey
                end
            end
        end

        context 'when the page contains JavaScript code' do
            it 'analyzes the DOM and pushes new pages to the page queue' do
                enable_browser_cluster

                SCNR::Engine::Framework.new do |f|
                    f.options.audit.elements :links, :forms, :cookies
                    f.checks.load :signature

                    expect(f.page_queue_total_size).to eq(0)

                    f.audit_page( SCNR::Engine::Page.from_url( url + '/with_javascript' ) )

                    sleep 0.1 while f.wait_for_browser_cluster?

                    expect(f.page_queue_total_size).to be > 0
                end
            end

            it 'analyzes the DOM and pushes new paths to the url queue' do
                enable_browser_cluster

                SCNR::Engine::Framework.new do |f|
                    f.options.url = url
                    f.options.audit.elements :links, :forms, :cookies

                    expect(f.url_queue_total_size).to eq(0)

                    f.audit_page( SCNR::Engine::Page.from_url( url + '/with_javascript' ) )

                    f.run

                    expect(f.url_queue_total_size).to eq(3)
                end
            end

            context 'when the DOM depth limit has been reached' do
                it 'does not analyze the DOM' do
                    SCNR::Engine::Framework.new do |f|
                        f.options.url = url

                        f.options.audit.elements :links, :forms, :cookies
                        f.checks.load :signature
                        f.options.scope.dom_depth_limit = 1

                        page = SCNR::Engine::Page.from_url( url + '/with_javascript' )
                        page.dom.push_transition SCNR::Engine::Page::DOM::Transition.new( :page, :load )
                        page.dom.push_transition SCNR::Engine::Page::DOM::Transition.new( :page, :load )

                        expect(f.audit_page( page )).to be_falsey
                    end
                end

                it 'returns false' do
                    page = SCNR::Engine::Page.from_data(
                        url:         url,
                        dom:         {
                            transitions: [
                                             { page: :load },
                                             { "<a href='javascript:click();'>" => :click },
                                             { "<button dblclick='javascript:doubleClick();'>" => :ondblclick }
                                         ].map { |t| SCNR::Engine::Page::DOM::Transition.new *t.first }
                        }
                    )

                    SCNR::Engine::Framework.new do |f|
                        f.checks.load :signature

                        f.options.scope.dom_depth_limit = 10
                        expect(f.audit_page( page )).to be_truthy

                        f.options.scope.dom_depth_limit = 2
                        expect(f.audit_page( page )).to be_falsey
                    end
                end
            end
        end

        context 'when the page matches exclusion criteria' do
            it 'does not audit it' do
                subject.options.scope.exclude_path_patterns << /link/
                subject.options.audit.elements :links, :forms, :cookies

                subject.checks.load :signature

                subject.audit_page( SCNR::Engine::Page.from_url( url + '/link' ) )
                expect(subject.report.issues.size).to eq(0)
            end

            it 'returns false' do
                subject.options.scope.exclude_path_patterns << /link/
                expect(subject.audit_page( SCNR::Engine::Page.from_url( url + '/link' ) )).to be_falsey
            end
        end

        context "when #{SCNR::Engine::Options}#platforms" do
            before do
                SCNR::Engine::Platform::Manager.reset
                subject.options.paths.fingerprinters = fixtures_path + '/empty/'
            end

            context 'have been provided' do
                context 'and are supported by the check' do
                    it 'audits it' do
                        subject.options.platforms = [:unix]
                        subject.options.audit.elements :links, :forms, :cookies

                        subject.checks.load :signature
                        subject.checks[:signature].platforms << :unix

                        subject.audit_page( SCNR::Engine::Page.from_url( url + '/link' ) )
                        expect(subject.report.issues).to be_any
                    end
                end

                context 'and are not supported by the check' do
                    it 'does not audit it' do
                        subject.options.platforms = [:windows]

                        subject.options.audit.elements :links, :forms, :cookies

                        subject.checks.load :signature
                        subject.checks[:signature].platforms << :unix

                        subject.audit_page( SCNR::Engine::Page.from_url( url + '/link' ) )
                        expect(subject.report.issues).to be_empty
                    end
                end
            end

            context 'have not been provided' do
                it 'audits it' do
                    subject.options.platforms = []
                    subject.options.audit.elements :links, :forms, :cookies

                    subject.checks.load :signature
                    subject.checks[:signature].platforms << :unix

                    subject.audit_page( SCNR::Engine::Page.from_url( url + '/link' ) )
                    expect(subject.report.issues).to be_any
                end
            end
        end

        context "when #{SCNR::Engine::Check::Auditor}.has_timeout_candidates?" do
            it "calls #{SCNR::Engine::Check::Auditor}.timeout_audit_run" do
                allow(SCNR::Engine::Check::Auditor).to receive(:has_timeout_candidates?){ true }

                expect(SCNR::Engine::Check::Auditor).to receive(:timeout_audit_run)
                subject.audit_page( SCNR::Engine::Page.from_url( url + '/link' ) )
            end
        end

        context 'when the page contains elements seen in previous pages' do
            it 'removes them from the page'
        end

        context 'when a check fails with an exception' do
            it 'moves to the next one' do
                enable_browser_cluster

                SCNR::Engine::Options.paths.checks  = fixtures_path + '/checks/'

                SCNR::Engine::Framework.new do |f|
                    f.checks.load_all

                    allow_any_instance_of(f.checks[:test]).to receive(:run) { raise }

                    page = SCNR::Engine::Page.from_url( url + '/link' )

                    responses = []
                    f.http.on_complete do |response|
                        responses << response.url
                    end

                    f.audit_page page

                    expect(responses).to eq(%w(http://localhost/test3 http://localhost/test2))
                end
            end
        end
    end

end
