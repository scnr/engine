require 'json'
require 'spec_helper'

describe 'SCNR::Engine::RPC::Server::Instance' do
    before( :each ) do
        SCNR::Engine::Options.browser_cluster.disable!
    end

    let(:subject) { instance_spawn }

    it 'supports UNIX sockets', if: Arachni::Reactor.supports_unix_sockets? do
        socket = "#{Dir.tmpdir}/scnr-engine-instance-#{SCNR::Engine::Utilities.generate_token}"
        subject = instance_spawn( socket: socket )

        expect(subject.url).to eq(socket)
        expect(subject.alive?).to be_truthy
    end

    describe '#snapshot_path' do
        context 'when the scan has not been suspended' do
            it 'returns nil' do
                expect(subject.snapshot_path).to be_nil
            end
        end

        context 'when the scan has been suspended' do
            it 'returns the path to the snapshot' do
                subject.scan(
                    url:    web_server_url_for( :framework_multi ),
                    audit:  { elements: [:links, :forms] },
                    checks: :test
                )

                Timeout.timeout 20 do
                    sleep 1 while subject.status != :scanning
                end

                subject.suspend

                Timeout.timeout 60 do
                    sleep 1 while subject.status != :suspended
                end

                expect(File.exists?( subject.snapshot_path )).to be_truthy
            end
        end
    end

    describe '#suspend' do
        it 'suspends the scan to disk' do
            subject.scan(
                url:    web_server_url_for( :framework_multi ),
                audit:  { elements: [:links, :forms] },
                checks: :test
            )

            Timeout.timeout 20 do
                sleep 1 while subject.status != :scanning
            end

            subject.suspend

            Timeout.timeout 60 do
                sleep 1 while subject.status != :suspended
            end

            expect(File.exists?( subject.snapshot_path )).to be_truthy
        end
    end

    describe '#suspended?' do
        context 'when the scan has not been suspended' do
            it 'returns false' do
                expect(subject.suspended?).to be_falsey
            end
        end

        context 'when the scan has been suspended' do
            it 'returns true' do
                subject.scan(
                    url:    web_server_url_for( :framework_multi ),
                    audit:  { elements: [:links, :forms] },
                    checks: :test
                )

                Timeout.timeout 20 do
                    sleep 1 while subject.status != :scanning
                end

                subject.suspend

                Timeout.timeout 60 do
                    sleep 1 while subject.status != :suspended
                end

                expect(subject.suspended?).to be_truthy
            end
        end
    end

    describe '#busy?' do
        context 'when the scan is not running' do
            it 'returns false' do
                expect(subject.busy?).to be_falsey
            end
        end

        context 'when the scan is running' do
            it 'returns true' do
                subject.scan(
                    url: web_server_url_for( :auditor ) + '/sleep',
                    checks: ['test']
                )
                expect(subject.busy?).to be_truthy
            end
        end
    end

    describe '#list_plugins' do
        it 'lists all available plugins' do
            plugins = subject.list_plugins
            expect(plugins.size).to eq(7)
            plugin = plugins.select { |i| i[:name] =~ /default/i }.first
            expect(plugin[:name]).to eq('Default')
            expect(plugin[:description]).to eq('Some description')
            expect(plugin[:author].size).to eq(1)
            expect(plugin[:author].first).to eq('Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>')
            expect(plugin[:version]).to eq('0.1')
            expect(plugin[:shortname]).to eq('default')
            expect(plugin[:options].size).to eq(1)

            opt = plugin[:options].first
            expect(opt[:name]).to eq(:int_opt)
            expect(opt[:required]).to eq(false)
            expect(opt[:description]).to eq('An integer.')
            expect(opt[:default]).to eq(4)
            expect(opt[:type]).to eq(:integer)
        end
    end

    describe '#list_reporters' do
        it 'lists all available reporters' do
            reporters = subject.list_reporters
            expect(reporters).to be_any
            report_with_opts = reporters.select{ |r| r[:options].any? }.first
            expect(report_with_opts[:options].first).to be_kind_of( Hash )
        end
    end

    describe '#list_checks' do
        it 'lists all available checks' do
            expect(subject.list_checks).to be_any
        end
    end

    describe '#list_platforms' do
        it 'lists all available platforms' do
            expect(subject.list_platforms).to eq(SCNR::Engine::Framework.unsafe.list_platforms)
        end
    end

    describe '#restore' do
        it 'suspends the scan to disk' do
            subject.scan(
                url:    web_server_url_for( :framework_multi ),
                audit:  { elements: [:links, :forms] },
                checks: :test
            )

            Timeout.timeout 20 do
                sleep 1 while subject.status != :scanning
            end

            options = subject.report[:options]

            subject.suspend

            Timeout.timeout 60 do
                sleep 1 while subject.status != :suspended
            end

            snapshot_path = subject.snapshot_path
            subject.shutdown

            subject = instance_spawn
            subject.restore snapshot_path

            File.delete snapshot_path

            sleep 1 while subject.status != :done

            expect(subject.report[:options]).to eq(options)
        end
    end

    describe '#errors' do
        before(:each) do
            subject.error_test error
        end
        let(:error) { "My error #{rand(9999)}" }

        context 'when no argument has been provided' do
            it 'returns all logged errors' do
                expect(subject.errors.last).to end_with error
            end
        end

        context 'when a start line-range has been provided' do
            it 'returns all logged errors after that line' do
                initial_errors = subject.errors
                errors = subject.errors( 10 )

                expect(initial_errors[10..-1]).to eq(errors)
            end
        end
    end

    describe '#error_logfile' do
        before(:each) do
            subject.error_test error
        end
        let(:error) { "My error #{rand(9999)}" }

        it 'returns the path to the error logfile' do
            errors = IO.read( subject.error_logfile )

            subject.errors.each do |error|
                expect(errors).to include error
            end
        end
    end

    describe '#alive?' do
        it 'returns true' do
            expect(subject.alive?).to eq(true)
        end
    end

    describe '#paused?' do
        context 'when not paused' do
            it 'returns false' do
                expect(subject.paused?).to be_falsey
            end
        end
        context 'when paused' do
            it 'returns true' do
                subject.scan(
                    url:    web_server_url_for( :framework ),
                    checks: :test
                )

                subject.pause
                Timeout.timeout 60 do
                    sleep 1 while !subject.paused?
                end

                expect(subject.paused?).to be_truthy
            end
        end
    end

    describe '#resume' do
        it 'resumes the scan' do
            subject.scan(
                url:    web_server_url_for( :framework ),
                checks: :test
            )

            subject.pause
            Timeout.timeout 60 do
                sleep 1 while !subject.paused?
            end

            expect(subject.paused?).to be_truthy
            expect(subject.resume).to be_truthy

            Timeout.timeout 20 do
                sleep 1 while subject.paused?
            end

            expect(subject.paused?).to be_falsey
        end
    end

    describe '#report' do
        it "returns #{SCNR::Engine::Framework}#report as a Hash" do
            expect(subject.report).to eq(
                SCNR::Engine::RPC::Serializer.load(
                    SCNR::Engine::RPC::Serializer.dump( subject.report.to_h )
                )
            )
        end
    end

    describe '#abort_and_report' do
        it 'cleans-up and returns the report as a Hash' do
            expect(subject.abort_and_report).to eq(
                SCNR::Engine::RPC::Serializer.load(
                    SCNR::Engine::RPC::Serializer.dump( subject.report.to_h )
                )
            )
        end
    end

    describe '#native_abort_and_report' do
        it "cleans-up and returns the report as #{SCNR::Engine::Report}" do
            expect(subject.native_abort_and_report).to be_kind_of SCNR::Engine::Report
        end
    end

    describe '#abort_and_report_as' do
        it 'cleans-up and delegate to #report_as' do
            expect(JSON.load( subject.abort_and_report_as( :json ) )).to include 'issues'
        end
    end

    describe '#report_as' do
        it 'delegates to Framework#report_as' do
            expect(JSON.load( subject.report_as( :json ) )).to include 'issues'
        end
    end

    describe '#status' do
        context 'after initialization' do
            it 'returns :ready' do
                expect(subject.status).to eq(:ready)
            end
        end

        context 'after #run has been called' do
            it 'returns :scanning' do
                subject.scan(
                    url: web_server_url_for( :framework ) + '/crawl',
                    checks: ['test']
                )

                sleep 2
                expect(subject.status).to eq(:scanning)
            end
        end

        context 'once the scan had completed' do
            it 'returns :done' do
                subject.scan(
                    url: web_server_url_for( :framework ) + '/crawl',
                    checks: ['test']
                )

                sleep 1 while subject.busy?
                expect(subject.status).to eq(:done)
            end
        end
    end

    describe '#scan' do
        it 'configures and starts a scan' do
            expect(subject.busy?).to  be false
            expect(subject.status).to be :ready

            subject.scan(
                url:    web_server_url_for( :framework ),
                audit:  { elements: [:links, :forms] },
                checks: :test
            )

            # if a scan in already running it should just bail out early
            expect(subject.scan).to be_falsey

            sleep 1 while subject.busy?

            expect(subject.busy?).to  be false
            expect(subject.status).to be :done
            expect(subject.report['issues']).to be_any
        end

        context 'with invalid :platforms' do
            it 'raises ArgumentError' do
                expect {
                    subject.scan(
                        url:       web_server_url_for( :framework ),
                        platforms: [ :stuff ]
                    )
                }.to raise_error
            end
        end
    end

    describe '#progress' do
        before( :each ) do
            subject.scan(
                url:    web_server_url_for( :framework ),
                audit:  { elements: [:links, :forms] },
                checks: :test
            )
            sleep 1 while subject.busy?
        end

        it 'returns progress information' do
            p = subject.progress
            expect(p[:busy]).to   be false
            expect(p[:status]).to be :done
            expect(p[:statistics]).to  be_any

            expect(p[:issues]).to be_nil
            expect(p[:seed]).not_to be_empty
        end

        describe ':without' do
            describe ':statistics' do
                it 'includes statistics' do
                    expect(subject.progress(
                        without: :statistics
                    )).not_to include :statistics
                end
            end

            describe ':issues' do
                it 'does not include issues with the given Issue#digest hashes' do
                    p = subject.progress( with: :issues )
                    issue = p[:issues].first
                    digest = issue['digest']

                    p = subject.progress(
                        with:    :issues,
                        without: { issues: [digest] }
                    )

                    expect(p[:issues].include?( issue )).to be_falsey
                end
            end

            context 'with an array of things to be excluded'  do
                it 'excludes those things' do
                    p = subject.progress( with: :issues )
                    issue = p[:issues].first
                    digest = issue['digest']

                    p = subject.progress(
                        with:    [ :issues ],
                        without: [ :statistics,  issues: [digest] ]
                    )
                    expect(p).not_to include :statistics
                    expect(p[:issues].include?( issue )).to be_falsey
                end
            end
        end

        describe ':with' do
            describe ':issues' do
                it 'includes issues' do
                    issues = subject.progress( with: :issues )[:issues]
                    expect(issues).to be_any
                    expect(issues.first.class).to eq(Hash)

                    issues.tap do
                        issues.each do |issue|
                            issue.delete 'platform_name'
                            issue.delete 'platform_type'
                        end
                    end

                    issues_h = SCNR::Engine::RPC::Serializer.load(
                        SCNR::Engine::RPC::Serializer.dump(
                            subject.native_report.issues.map(&:to_h)
                        )
                    )
                    expect(issues).to eq(issues_h)
                end
            end

            describe ':sitemap' do
                context 'when set to true' do
                    it 'returns entire sitemap' do
                        expect(subject.
                            progress( with: { sitemap: true } )[:sitemap]).to eq(
                                subject.sitemap
                        )
                    end
                end

                context 'when an index has been provided' do
                    it 'returns all entries after that line' do
                        expect(subject.
                            progress( with: { sitemap: 10 } )[:sitemap]).to eq(
                                subject.sitemap( 10 )
                        )
                    end
                end
            end

            context 'with an array of things to be included'  do
                it 'includes those things' do
                    p = subject.progress(
                        with:    [ :issues ],
                        without: :statistics
                    )
                    expect(p[:busy]).to   be false
                    expect(p[:status]).to be :done
                    expect(p[:statistics]).to  be_nil

                    expect(p[:issues]).to be_any
                end
            end
        end
    end

    describe '#native_progress' do
        before( :each ) do
            subject.scan(
                url:    web_server_url_for( :framework ),
                audit:  { elements: [:links, :forms] },
                checks: :test
            )
            sleep 1 while subject.busy?
        end

        it 'returns progress information' do
            p = subject.native_progress
            expect(p[:busy]).to   be false
            expect(p[:status]).to be :done
            expect(p[:statistics]).to  be_any

            expect(p[:issues]).to be_nil
        end

        describe ':without' do
            describe ':statistics' do
                it 'includes statistics' do
                    expect(subject.native_progress(
                        without: :statistics
                    )).not_to include :statistics
                end
            end

            describe ':issues' do
                it 'does not include issues with the given Issue#digest hashes' do
                    p = subject.native_progress( with: :issues )
                    issue = p[:issues].first
                    digest = issue.digest

                    p = subject.native_progress(
                        with:    :issues,
                        without: { issues: [digest] }
                    )

                    expect(p[:issues].include?( issue )).to be_falsey
                end
            end

            context 'with an array of things to be excluded'  do
                it 'excludes those things' do
                    p = subject.native_progress( with: :issues )
                    issue = p[:issues].first
                    digest = issue.digest

                    p = subject.native_progress(
                        with:    [ :issues ],
                        without: [ :statistics,  issues: [digest] ]
                    )
                    expect(p).not_to include :statistics
                    expect(p[:issues].include?( issue )).to be_falsey
                end
            end
        end

        describe ':with' do
            describe ':issues' do
                it 'includes issues as SCNR::Engine::Issue objects' do
                    issues = subject.native_progress( with: :issues )[:issues]
                    expect(issues).to be_any
                    expect(issues.first.class).to eq(SCNR::Engine::Issue)
                end
            end

            context 'with an array of things to be included'  do
                it 'includes those things' do
                    p = subject.native_progress(
                        with:    [ :issues ],
                        without: :statistics
                    )
                    expect(p[:busy]).to   be false
                    expect(p[:status]).to be :done
                    expect(p[:statistics]).to  be_nil

                    expect(p[:issues]).to be_any
                end
            end
        end
    end

    describe '#shutdown' do
        it 'shuts-down the instance' do
            expect(subject.shutdown).to be_truthy
            sleep 4

            expect { subject.alive? }.to raise_error Arachni::RPC::Exceptions::ConnectionError
        end
    end

end
