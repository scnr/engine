require 'spec_helper'

describe name_from_filename do
    include_examples 'plugin'

    before :each do
        SCNR::Engine::Options.url = url
        options.session.check_url     = nil
        options.session.check_pattern = nil

        IO.write( script_path, script )

        options.plugins[component_name] = { 'script' => script_path }

        SCNR::Engine::Options.dom.pool_size = 1
        SCNR::Engine::Options.scope.dom_depth_limit = 1
    end

    after(:each) { FileUtils.rm_f script_path }

    let(:script) { '' }
    let(:script_path) { "#{Dir.tmpdir}/login_script_#{Time.now.to_i}" }

    context 'when a browser' do
        context 'is available' do
            let(:script) do
                <<EOSCRIPT
            SCNR::Engine::Options.datastore.browser = browser.class.to_s
            SCNR::Engine::Options.datastore.window_width = browser.execute_script( 'return window.innerWidth;' )
            SCNR::Engine::Options.datastore.window_height = browser.execute_script( 'return window.innerHeight;' )
EOSCRIPT
            end

            it "exposes a Watir::Browser interface via the 'browser' variable" do
                run

                expect(options.datastore.browser).to eq 'Watir::Browser'
            end

            it 'sets the appropriate resolution' do
                run

                expect(SCNR::Engine::Options.datastore.window_width).to eq SCNR::Engine::Options.device.width
                expect(SCNR::Engine::Options.datastore.window_height).to eq SCNR::Engine::Options.device.height
            end
        end

        context 'is not available' do
            before do
                SCNR::Engine::Options.scope.dom_depth_limit = 0
            end

            let(:script) do
                <<EOSCRIPT
                SCNR::Engine::Options.datastore.browser = browser
EOSCRIPT
            end

            it "sets 'browser' to 'nil'" do
                run

                expect(options.datastore.browser).to be_nil
            end

        end
    end

    context 'when the login was successful' do
        before :each do
            options.session.check_url     = url
            options.session.check_pattern = 'Hi there logged-in user'
        end

        let(:script) do
            <<EOSCRIPT
                http.cookie_jar.update 'success' => 'true'
EOSCRIPT
        end

        it 'sets the status' do
            run

            expect(actual_results['status']).to  eq('success')
        end

        it 'sets the message' do
            run

            expect(actual_results['message']).to eq(plugin::STATUSES[:success])
        end

        it 'sets the cookies' do
            run

            expect(actual_results['cookies']).to eq({ 'success' => 'true' })
        end
    end

    context 'when there is no session check' do
        let(:script) do
            <<EOSCRIPT
                http.cookie_jar.update 'success' => 'true'
EOSCRIPT
        end

        it 'sets the status' do
            run

            expect(actual_results['status']).to  eq('missing_check')
        end

        it 'sets the message' do
            run

            expect(actual_results['message']).to eq(plugin::STATUSES[:missing_check])
        end

        it 'aborts the scan' do
            run

            expect(framework.status).to eq(:aborted)
        end
    end

    context 'when the session check fails' do
        before :each do
            options.session.check_url     = url
            options.session.check_pattern = 'Hi there logged-in user'
        end

        it 'sets the status' do
            run

            expect(actual_results['status']).to  eq('failure')
        end

        it 'sets the message' do
            run

            expect(actual_results['message']).to eq(plugin::STATUSES[:failure])
        end

        it 'aborts the scan' do
            run

            expect(framework.status).to eq(:aborted)
        end
    end

    context 'when there is a runtime error in the script' do
        let(:script) do
            <<EOSCRIPT
                fail
EOSCRIPT
        end

        it 'sets the status' do
            run

            expect(actual_results['status']).to  eq('error')
        end

        it 'sets the message' do
            run

            expect(actual_results['message']).to eq(plugin::STATUSES[:error])
        end

        it 'aborts the scan' do
            run

            expect(framework.status).to eq(:aborted)
        end
    end

    context 'when there is a syntax error in the script' do
        let(:script) do
            <<EOSCRIPT
                {
                    id: => stuff
                }
EOSCRIPT
        end

        it 'sets the status' do
            run

            expect(actual_results['status']).to  eq('error')
        end

        it 'sets the message' do
            run

            expect(actual_results['message']).to eq(plugin::STATUSES[:error])
        end

        it 'aborts the scan' do
            run

            expect(framework.status).to eq(:aborted)
        end
    end

end
