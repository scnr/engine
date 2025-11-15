require 'spec_helper'

describe SCNR::Engine::Framework do
    include_examples 'framework'

    describe '#version' do
        it "returns #{SCNR::Engine::VERSION}" do
            expect(subject.version).to eq(SCNR::Engine::VERSION)
        end
    end

    describe '#run' do
        it 'follows redirects' do
            SCNR::Engine::Options.url = f_url + '/redirect'
            subject.run
            expect(subject.sitemap).to eq({
                "#{f_url}/redirect"   => 302,
                "#{f_url}/redirected" => 200
            })
        end

        it 'performs the scan' do
            SCNR::Engine::Options.url = url + '/elem_combo'
            SCNR::Engine::Options.audit.elements :links, :forms, :cookies
            subject.checks.load :signature
            subject.plugins.load :wait

            subject.run
            expect(subject.report.issues.size).to eq(3)

            expect(subject.report.plugins[:wait][:results]).to eq({ 'stuff' => true })
        end

        it 'performs an OpenAPI scan', focus: true do
            SCNR::Engine::Options.url = url + '/openapi'
            SCNR::Engine::Options.audit.elements :links, :forms, :cookies
            subject.checks.load :signature
            subject.plugins.load :wait

            subject.run
            expect(subject.report.issues.size).to eq(3)

            expect(subject.report.plugins[:wait][:results]).to eq({ 'stuff' => true })
        end

        it 'sets #status to scanning' do
            described_class.safe do |f|
                SCNR::Engine::Options.url = url + '/elem_combo'
                SCNR::Engine::Options.audit.elements :links, :forms, :cookies
                f.checks.load :signature

                t = Thread.new { f.run }
                Timeout.timeout( 5 ) do
                    sleep 0.1 while f.status != :scanning
                end
                t.join
            end
        end

        it 'handles heavy load' do
            SCNR::Engine::Options.paths.checks = fixtures_path + '/signature_check/'

            SCNR::Engine::Framework.safe do |f|
                SCNR::Engine::Options.url = web_server_url_for :framework_multi
                SCNR::Engine::Options.audit.elements :links

                f.checks.load :signature

                f.run
                expect(f.report.issues.size).to eq(500)
            end
        end

        it 'handles pages with JavaScript code' do
            enable_dom

            SCNR::Engine::Framework.safe do |f|
                SCNR::Engine::Options.url = url + '/with_javascript'
                SCNR::Engine::Options.audit.elements :links, :forms, :cookies

                f.checks.load :signature
                f.run

                expect(
                    f.report.issues.
                        map { |i| i.vector.affected_input_name }.
                        uniq.sort
                ).to eq(%w(link_input form_input cookie_input).sort)
            end
        end

        it 'handles AJAX' do
            enable_dom

            SCNR::Engine::Framework.safe do |f|
                SCNR::Engine::Options.url = url + '/with_ajax'
                SCNR::Engine::Options.audit.elements :links, :forms, :cookies

                f.checks.load :signature
                f.run

                expect(
                    f.report.issues.
                        map { |i| i.vector.affected_input_name }.
                        uniq.sort
                ).to eq(%w(link_input form_input cookie_taint).sort)
            end
        end

        context 'when done' do
            it 'sets #status to :done' do
                described_class.safe do |f|
                    SCNR::Engine::Options.url = url + '/elem_combo'
                    SCNR::Engine::Options.audit.elements :links, :forms, :cookies
                    f.checks.load :signature

                    f.run
                    expect(f.status).to eq(:done)
                end
            end
        end

        context 'when it has log-in capabilities and gets logged out' do
            it 'logs-in again before continuing with the audit' do
                enable_dom

                SCNR::Engine::Framework.safe do |f|
                    url = web_server_url_for( :framework ) + '/'
                    SCNR::Engine::Options.url = "#{url}/congrats"

                    SCNR::Engine::Options.audit.elements :links, :forms
                    f.checks.load_all

                    f.session.configure(
                        url:    url,
                        inputs: {
                            username: 'john',
                            password: 'doe'
                        }
                    )

                    SCNR::Engine::Options.session.check_url     = url
                    SCNR::Engine::Options.session.check_pattern = 'logged-in user'

                    f.run
                    expect(f.report.issues.size).to eq(1)
                end
            end
        end
    end

    describe '#statistics' do
        let(:statistics) { subject.statistics }

        it 'includes http statistics' do
            expect(statistics[:http]).to eq(subject.http.statistics)
        end

        it 'includes browser cluster statistics' do
            expect(statistics[:browser_pool]).to eq(SCNR::Engine::BrowserPool.statistics)
        end

        [:found_pages, :audited_pages, :current_page].each  do |k|
            it "includes #{k}" do
                expect(statistics).to include k
            end
        end

        describe ':runtime' do
            context 'when the scan has been running' do
                it 'returns the runtime in seconds' do
                    subject.run
                    expect(statistics[:runtime]).to be > 0
                end
            end

            context 'when no scan has been running' do
                it 'returns 0' do
                    expect(statistics[:runtime]).to eq(0)
                end
            end
        end
    end

end
