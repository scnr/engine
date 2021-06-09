require 'spec_helper'

describe SCNR::Engine::Framework::Parts::State do
    include_examples 'framework'

    let(:multi_url) { web_server_url_for( :framework_multi ) }

    describe "#{SCNR::Engine::OptionGroups::Timeout}" do
        describe '#duration' do
            it 'aborts when it is exceeded' do
                timeout = 5
                SCNR::Engine::Options.timeout.duration = timeout
                SCNR::Engine::Options.paths.checks     = fixtures_path + '/signature_check/'

                SCNR::Engine::Framework.safe do |f|
                    SCNR::Engine::Options.url = web_server_url_for :framework_multi
                    SCNR::Engine::Options.audit.elements :links

                    f.plugins.load :wait
                    f.checks.load :signature
                    f.run

                    expect(f.statistics[:runtime]).to be > timeout
                    expect(f.statistics[:runtime]).to be < timeout + 1
                    expect(SCNR::Engine::Data.issues.size).to be < 500
                    expect(f.state.status).to be :timed_out
                end
            end

            describe '#suspend' do
                it 'suspends the scan' do
                    timeout = 5
                    SCNR::Engine::Options.timeout.duration = timeout
                    SCNR::Engine::Options.timeout.suspend  = true
                    SCNR::Engine::Options.paths.checks     = fixtures_path + '/signature_check/'

                    SCNR::Engine::Framework.safe do |f|
                        SCNR::Engine::Options.url = web_server_url_for :framework_multi
                        SCNR::Engine::Options.audit.elements :links

                        f.plugins.load :wait
                        f.checks.load :signature
                        f.run

                        expect(f.statistics[:runtime]).to be > timeout
                        expect(f.statistics[:runtime]).to be < timeout + 1
                        expect(SCNR::Engine::Data.issues.size).to be < 500
                        expect(f.state.status).to be :suspended
                        expect(SCNR::Engine::Snapshot.load( f.snapshot_path )).to be_truthy
                    end
                end
            end
        end
    end

    describe '#scanning?' do
        it "delegates to #{SCNR::Engine::State::Framework}#scanning?" do
            allow(subject.state).to receive(:scanning?) { :stuff }
            expect(subject.scanning?).to eq(:stuff)
        end
    end

    describe '#done?' do
        it "delegates to #{SCNR::Engine::State::Framework}#done?" do
            allow(subject.state).to receive(:done?) { :stuff }
            expect(subject.done?).to eq(:stuff)
        end
    end

    describe '#paused?' do
        it "delegates to #{SCNR::Engine::State::Framework}#paused?" do
            allow(subject.state).to receive(:paused?) { :stuff }
            expect(subject.paused?).to eq(:stuff)
        end
    end

    describe '#state' do
        it "returns #{SCNR::Engine::State::Framework}" do
            expect(subject.state).to be_kind_of SCNR::Engine::State::Framework
        end
    end

    describe '#abort!' do
        it 'aborts the system' do
            SCNR::Engine::Options.paths.checks  = fixtures_path + '/signature_check/'

            SCNR::Engine::Framework.safe do |f|
                SCNR::Engine::Options.url = web_server_url_for :framework_multi
                SCNR::Engine::Options.audit.elements :links

                f.checks.load :signature

                t = Thread.new do
                    f.run
                end

                sleep 0.1 while SCNR::Engine::Data.issues.size < 2

                f.abort!
                t.join

                expect(SCNR::Engine::Data.issues.size).to be < 500
            end
        end

        it 'sets #status to :aborted' do
            SCNR::Engine::Framework.safe do |f|
                SCNR::Engine::Options.url = web_server_url_for :framework_multi
                SCNR::Engine::Options.audit.elements :links
                f.checks.load :signature

                t = Thread.new do
                    f.run
                end
                sleep 0.1 while f.status != :scanning

                f.abort!
                t.join
                expect(f.status).to eq(:aborted)
            end
        end
    end

    describe '#suspend!' do
        it 'suspends the system' do
            SCNR::Engine::Options.paths.checks = fixtures_path + '/signature_check/'

            snapshot = nil
            SCNR::Engine::Framework.safe do |f|
                SCNR::Engine::Options.url = web_server_url_for :framework_multi
                SCNR::Engine::Options.audit.elements :links

                f.checks.load :signature

                t = Thread.new do
                    f.run
                end

                sleep 0.1 while SCNR::Engine::Data.issues.size < 2

                snapshot = f.suspend!
                t.join

                expect(SCNR::Engine::Data.issues.size).to be < 500
            end

            expect(SCNR::Engine::Snapshot.load( snapshot )).to be_truthy
        end

        it 'sets #status to :suspended' do
            SCNR::Engine::Framework.safe do |f|
                SCNR::Engine::Options.url = web_server_url_for :framework_multi
                SCNR::Engine::Options.audit.elements :links
                f.checks.load :signature

                t = Thread.new do
                    f.run
                end
                sleep 0.1 while f.status != :scanning

                f.suspend!
                t.join
                expect(f.status).to eq(:suspended)
            end
        end

        it 'suspends plugins' do
            SCNR::Engine::Options.plugins['suspendable'] = {
                'my_option' => 'my value'
            }

            SCNR::Engine::Framework.safe do |f|
                SCNR::Engine::Options.url = web_server_url_for :framework_multi
                SCNR::Engine::Options.audit.elements :links

                f.checks.load :signature
                f.plugins.load :suspendable

                t = Thread.new do
                    f.run
                end

                sleep 0.1 while f.status != :scanning

                f.suspend!
                t.join

                expect(SCNR::Engine::State.plugins.runtime[:suspendable][:data]).to eq(1)
            end
        end

        it 'waits for the BrowserCluster jobs to finish'

        context "when #{SCNR::Engine::OptionGroups::Paths}#snapshots" do
            context 'is a directory' do
                it 'stores the snapshot under it' do
                    SCNR::Engine::Options.paths.checks  = fixtures_path + '/signature_check/'
                    SCNR::Engine::Options.snapshot.path = Dir.tmpdir

                    snapshot = nil
                    SCNR::Engine::Framework.safe do |f|
                        SCNR::Engine::Options.url = web_server_url_for :framework_multi
                        SCNR::Engine::Options.audit.elements :links

                        f.plugins.load :wait
                        f.checks.load :signature

                        t = Thread.new do
                            f.run
                        end

                        sleep 0.1 while SCNR::Engine::Data.issues.size < 2

                        snapshot = f.suspend!
                        t.join

                        expect(SCNR::Engine::Data.issues.size).to be < 500
                    end

                    expect(File.dirname( snapshot )).to eq(Dir.tmpdir)
                    expect(SCNR::Engine::Snapshot.load( snapshot )).to be_truthy
                end
            end

            context 'is a file path' do
                it 'stores the snapshot there' do
                    SCNR::Engine::Options.paths.checks    = fixtures_path + '/signature_check/'
                    SCNR::Engine::Options.snapshot.path = "#{Dir.tmpdir}/snapshot"

                    snapshot = nil
                    SCNR::Engine::Framework.safe do |f|
                        SCNR::Engine::Options.url = web_server_url_for :framework_multi
                        SCNR::Engine::Options.audit.elements :links

                        f.plugins.load :wait
                        f.checks.load :signature

                        t = Thread.new do
                            f.run
                        end

                        sleep 0.1 while SCNR::Engine::Data.issues.size < 2

                        snapshot = f.suspend!
                        t.join

                        expect(SCNR::Engine::Data.issues.size).to be < 500
                    end

                    expect(snapshot).to eq("#{Dir.tmpdir}/snapshot")
                    expect(SCNR::Engine::Snapshot.load( snapshot )).to be_truthy
                end
            end
        end
    end

    describe '#restore!' do
        it 'restores a suspended scan' do
            SCNR::Engine::Options.paths.checks  = fixtures_path + '/signature_check/'

            logged_issues = 0
            snapshot = nil
            SCNR::Engine::Framework.safe do |f|
                SCNR::Engine::Options.url = multi_url
                SCNR::Engine::Options.audit.elements :links

                f.plugins.load :wait
                f.checks.load :signature

                SCNR::Engine::Data.issues.on_new do
                    logged_issues += 1
                end

                t = Thread.new do
                    f.run
                end

                sleep 0.1 while logged_issues < 200

                snapshot = f.suspend!
                t.join

                expect(logged_issues).to be < 500
            end

            reset_options
            SCNR::Engine::Options.paths.checks  = fixtures_path + '/signature_check/'

            SCNR::Engine::Framework.safe do |f|
                f.restore! snapshot

                SCNR::Engine::Data.issues.on_new do
                    logged_issues += 1
                end
                f.run

                expect(SCNR::Engine::Data.issues.size).to eq(500)

                expect(f.report.plugins[:wait][:results]).to eq({ 'stuff' => true })
            end
        end

        it 'restores options' do
            options_hash = nil

            snapshot = nil
            SCNR::Engine::Framework.safe do |f|
                SCNR::Engine::Options.url = multi_url
                SCNR::Engine::Options.audit.elements :links, :forms, :cookies
                SCNR::Engine::Options.datastore.my_custom_option = 'my custom value'
                options_hash = SCNR::Engine::Options.update( SCNR::Engine::Options.to_rpc_data ).to_h.deep_clone

                f.checks.load :signature

                t = Thread.new { f.run }
                sleep 0.1 while f.status != :scanning

                snapshot = f.suspend!

                t.join
            end

            SCNR::Engine::Framework.restore!( snapshot ) do |f|
                opts = SCNR::Engine::Options.to_h
                opts.delete :timeout
                options_hash.delete :timeout

                expect(opts).to eq(options_hash.merge( checks: ['signature'] ))
            end
        end

        it 'restores BrowserCluster skip states' do
            enable_browser_cluster

            snapshot = nil
            SCNR::Engine::Framework.safe do |f|
                SCNR::Engine::Options.url = url + '/with_ajax'
                SCNR::Engine::Options.audit.elements :links, :forms, :cookies

                f.checks.load :signature

                t = Thread.new { f.run }

                sleep 0.1 while f.browser_cluster.done?
                snapshot = f.suspend!

                t.join
            end

            SCNR::Engine::Framework.restore!( snapshot ) do |f|
                expect(f.browser_cluster_job_skip_states).to be_any
            end
        end

        it 'restores loaded checks' do
            snapshot = nil

            SCNR::Engine::Framework.safe do |f|
                SCNR::Engine::Options.url = multi_url
                f.checks.load :signature

                t = Thread.new { f.run }
                sleep 0.1 while f.status != :scanning

                snapshot = f.suspend!

                t.join
            end

            SCNR::Engine::Framework.restore!( snapshot ) do |f|
                expect(f.checks.loaded).to eq(['signature'])
            end
        end

        it 'restores loaded plugins' do
            snapshot = nil

            SCNR::Engine::Framework.safe do |f|
                SCNR::Engine::Options.url = multi_url
                f.plugins.load :wait

                t = Thread.new { f.run }
                sleep 0.1 while f.status != :scanning

                snapshot = f.suspend!
                t.join
            end

            SCNR::Engine::Framework.restore!( snapshot ) do |f|
                expect(f.plugins.loaded).to eq(['wait'])
            end
        end

        it 'restores plugin states' do
            SCNR::Engine::Options.plugins['suspendable'] = {
                'my_option' => 'my value'
            }

            snapshot = nil
            SCNR::Engine::Framework.safe do |f|
                SCNR::Engine::Options.url = multi_url
                SCNR::Engine::Options.audit.elements :links

                f.checks.load :signature
                f.plugins.load :suspendable

                t = Thread.new do
                    f.run
                end

                sleep 0.1 while f.status != :scanning

                snapshot = f.suspend!
                t.join

                expect(SCNR::Engine::State.plugins.runtime[:suspendable][:data]).to eq(1)
            end

            SCNR::Engine::Framework.restore!( snapshot ) do |f|
                t = Thread.new do
                    f.run
                end

                sleep 0.1 while f.status != :scanning

                expect(f.plugins.jobs[:suspendable][:instance].counter).to eq(2)

                f.abort!
                t.join
            end
        end
    end

    describe '#pause!' do
        it 'pauses the system' do
            SCNR::Engine::Framework.safe do |f|
                SCNR::Engine::Options.url = url + '/elem_combo'
                SCNR::Engine::Options.audit.elements :links, :forms, :cookies
                f.checks.load :signature

                t = Thread.new do
                    f.run
                end
                sleep 0.1 while f.status != :scanning

                f.pause!

                Timeout.timeout 5 do
                    sleep 0.1 while f.status != :paused
                end

                f.resume!
                t.join
            end
        end
    end

    describe '#resume!' do
        it 'resumes the scan' do
            SCNR::Engine::Framework.safe do |f|
                SCNR::Engine::Options.url = url + '/elem_combo'
                SCNR::Engine::Options.audit.elements :links, :forms, :cookies
                f.checks.load :signature

                t = Thread.new do
                    f.run
                end

                f.pause!
                Timeout.timeout 5 do
                    sleep 0.1 while f.status != :paused
                end

                f.resume!
                Timeout.timeout( 5 ) do
                    sleep 0.1 while f.status != :scanning
                end

                t.join
            end
        end
    end

    describe '#clean_up' do
        it 'shuts down the #browser_cluster' do
            enable_browser_cluster

            SCNR::Engine::Framework.safe do |f|
                SCNR::Engine::Options.url = url + '/elem_combo'

                expect(f.browser_cluster).to receive(:shutdown).at_least(:once)
                f.clean_up
            end
        end

        it 'stops the #plugins' do
            SCNR::Engine::Framework.safe do |f|
                SCNR::Engine::Options.url = url + '/elem_combo'
                f.plugins.load :wait

                f.plugins.run
                f.clean_up
                expect(f.plugins.jobs).to be_empty
            end
        end

        it 'sets the status to cleanup' do
            SCNR::Engine::Framework.safe do |f|
                SCNR::Engine::Options.url = url + '/elem_combo'

                f.clean_up
                expect(f.status).to eq(:cleanup)
            end
        end

        it 'clears the page queue' do
            SCNR::Engine::Framework.safe do |f|
                SCNR::Engine::Options.url = url + '/elem_combo'
                f.push_to_page_queue SCNR::Engine::Page.from_url( SCNR::Engine::Options.url )

                expect(f.data.page_queue).not_to be_empty
                f.clean_up
                expect(f.data.page_queue).to be_empty
            end
        end

        it 'clears the URL queue' do
            SCNR::Engine::Framework.safe do |f|
                SCNR::Engine::Options.url = url + '/elem_combo'
                f.push_to_url_queue SCNR::Engine::Options.url

                expect(f.data.url_queue).not_to be_empty
                f.clean_up
                expect(f.data.url_queue).to be_empty
            end
        end

        it 'sets #running? to false' do
            SCNR::Engine::Framework.safe do |f|
                SCNR::Engine::Options.url = url + '/elem_combo'
                f.clean_up
                expect(f).not_to be_running
            end
        end
    end

end
