require 'spec_helper'

describe SCNR::Engine::BrowserPool do

    subject { described_class.new }
    let(:url) { SCNR::Engine::Utilities.normalize_url( web_server_url_for( :browser ) ) }
    let(:args) { [] }
    let(:job) do
        SCNR::Engine::BrowserPool::Jobs::DOMExploration.new( job_options )
    end
    let(:job_options) do
        {
            resource: SCNR::Engine::HTTP::Client.get( url + 'explore', mode: :sync ),
            args:     args
        }
    end
    let(:custom_job) { Factory[:custom_job] }

    describe '.on_pop' do
        it 'assigns blocks to be passed each poped job' do
            cj = nil

            described_class.on_pop do |j|
                cj ||= j
            end
            bc = described_class.new( size: 1 )

            bc.queue job, (proc_to_method{})
            bc.wait

            expect(cj.id).to eq(job.id)
        end
    end

    describe '.on_queue' do
        it 'assigns blocks to be passed each queued job' do
            cj = nil
            described_class.on_queue do |j|
                cj ||= j
            end

            bc = described_class.new( size: 1 )

            bc.queue job, (proc_to_method{})

            expect(cj.id).to eq(job.id)
            bc.wait
        end
    end

    describe '.on_job_done' do
        it 'assigns blocks to be passed each finished job' do
            cj = nil

            described_class.on_job_done do |j|
                cj ||= j
            end
            bc = described_class.new( size: 1 )

            bc.queue job, (proc_to_method{})
            bc.wait

            expect(cj.id).to eq(job.id)
        end
    end

    describe '.on_result' do
        it 'assigns blocks to be passed each job result' do
            cj = nil

            described_class.on_result do |result|
                cj ||= result.job
            end

            bc = described_class.new( size: 1 )

            bc.queue job, (proc_to_method{})
            bc.wait

            expect(cj.id).to eq(job.id)
        end
    end

    describe '#initialize' do
        it "sets window width to #{SCNR::Engine::OptionGroups::Device}#width" do
            SCNR::Engine::Options.device.width = 400

            subject.workers.each do |browser|
                browser.load url
                expect(browser.window_width).to eq(400)
            end
        end

        it "sets window height to #{SCNR::Engine::OptionGroups::Device}#height" do
            SCNR::Engine::Options.device.height = 200

            subject.workers.each do |browser|
                browser.load url
                expect(browser.window_height).to eq(200)
            end
        end

        describe ':size' do
            it 'sets the amount of browsers to instantiate' do
                expect(described_class.new( size: 3 ).workers.size).to eq(3)
            end

            it "defaults to #{described_class::POOL_SIZE}#size" do
                expect(subject.workers.size).to eq(described_class::POOL_SIZE)
            end
        end

        describe ':on_pop' do
            it 'assigns blocks to be passed each poped job' do
                cj = nil
                bc = described_class.new(
                    size: 1,
                    on_pop:    proc do |j|
                        cj ||= j
                    end
                )

                bc.queue job, (proc_to_method{})
                bc.wait

                expect(cj.id).to eq(job.id)
            end
        end

        describe 'when a block is given' do
            it 'uses it to show preference to a job category' do
                call_order = []
                bc = described_class.new(
                    size: 1,
                    on_pop:    proc do |j|
                        call_order << j.category
                    end
                ) do
                    :stuff2
                end

                job.category = :stuff
                bc.queue job, (proc_to_method{})

                job2 = job.class.new( job_options )
                job2.category = :stuff2
                bc.queue job2, (proc_to_method{})

                job3 = job.class.new( job_options )
                job3.category = :stuff3
                bc.queue job3, (proc_to_method{})

                bc.wait

                expect(call_order.first).to be :stuff2
            end
        end
    end

    describe '.statistics' do
        it 'includes :queued_job_count' do
            current = described_class.statistics[:queued_job_count]
            subject.with_browser( proc_to_method{} )
            subject.with_browser( proc_to_method{} )
            subject.with_browser( proc_to_method{} )
            subject.wait

            expect(described_class.statistics[:queued_job_count] - current).to eq 3
        end

        it 'includes :completed_job_count' do
            current = described_class.statistics[:completed_job_count]
            subject.with_browser( proc_to_method{} )
            subject.with_browser( proc_to_method{} )
            subject.with_browser( proc_to_method{} )
            subject.wait

            expect(described_class.statistics[:completed_job_count] - current).to eq 3
        end
    end

    describe '#with_browser' do
        it 'provides a worker to the block' do
            worker = nil

            subject.with_browser( proc_to_method do |browser|
                worker = browser
            end)
            subject.wait

            expect(worker).to be_kind_of described_class::Worker
        end

        context 'when arguments have been provided' do
            it 'passes them to the callback' do
                worker = nil

                aa, bb, cc = nil
                subject.with_browser 1, 2, 3, (proc_to_method do |browser, a, b, c|
                    worker = browser
                    aa = a
                    bb = b
                    cc = c
                end)
                subject.wait

                expect(aa).to eq 1
                expect(bb).to eq 2
                expect(cc).to eq 3
                expect(worker).to be_kind_of described_class::Worker
            end
        end
    end

    describe '#javascript_token' do
        it 'returns the Javascript token used to namespace the custom JS environment' do
            expect(subject.javascript_token).to eq SCNR::Engine::Browser::Javascript.token
        end
    end

    describe '#pending_job_counter' do
        it 'returns the amount of pending jobs' do
            expect(subject.pending_job_counter).to eq(0)

            while_in_progress = []
            subject.queue job, (proc_to_method do
                while_in_progress << subject.pending_job_counter
            end)
            subject.wait

            expect(while_in_progress).to be_any
            while_in_progress.each do |pending_job_counter|
                expect(pending_job_counter).to be > 0
            end

            expect(subject.pending_job_counter).to eq(0)
        end
    end

    describe '#queue' do
        it 'processes the job' do
            pages = []

            subject.queue job, (proc_to_method do |result|
                pages << result.page
            end)
            subject.wait

            browser_explore_check_pages pages
        end

        it 'passes self to the callback' do
            pages = []

            subject.queue job, (proc_to_method do |result, cluster|
                expect(cluster).to eq(subject)
                pages << result.page
            end)
            subject.wait

            browser_explore_check_pages pages
        end

        it 'supports custom jobs' do
            results = []

            # We need to introduce the custom Job into the parent namespace
            # prior to the BrowserPool initialization, in order for it to be
            # available in the Peers' namespace.
            custom_job

            subject.queue custom_job, (proc_to_method do |result|
                results << result
            end)
            subject.wait

            expect(results.size).to eq(1)
            result = results.first
            expect(result.my_data).to eq('Some stuff')
            expect(result.job.id).to eq(custom_job.id)
        end

        context 'when a callback argument is given' do
            it 'sets it as a callback' do
                pages = []

                m =  proc_to_method do |result, cluster|
                    expect(cluster).to eq(subject)
                    pages << result.page
                end

                subject.queue( job, m )
                subject.wait

                browser_explore_check_pages pages
            end
        end

        context 'when a block is given' do
            it "raises an #{ArgumentError}"
        end

        context 'when the given method' do
            context 'belongs to an instance' do
                it "raises an #{ArgumentError}"
            end
        end

        context 'when Job#args have been set' do
            let(:args) { [1, 2] }

            it 'passes them to the callback' do
                pages = []
                subject.queue job, (proc_to_method do |result, a, b|
                    expect(a).to eq args[0]
                    expect(b).to eq args[1]

                    pages << result.page
                end)
                subject.wait

                browser_explore_check_pages pages
            end
        end

        context 'when no callback has been provided' do
            it 'raises ArgumentError' do
                expect { subject.queue( job ) }.to raise_error ArgumentError
            end
        end

        context 'when the job has been marked as done' do
            it "raises #{described_class::Job::Error::AlreadyDone}" do
                subject.queue job, (proc_to_method {})
                subject.job_done( job )
                expect { subject.queue( job, (proc_to_method {}) ) }.to raise_error described_class::Job::Error::AlreadyDone
            end

            context 'and the job is marked as #never_ending' do
                it 'preserves the analysis state between calls' do
                    pages = []

                    job.never_ending = true
                    subject.queue job, (proc_to_method do |result|
                        expect(result.job.never_ending?).to be_truthy
                        pages << result.page
                    end)
                    subject.wait
                    browser_explore_check_pages pages

                    pages = []
                    subject.queue job, (proc_to_method do |result|
                        expect(result.job.never_ending?).to be_truthy
                        pages << result.page
                    end)
                    subject.wait
                    expect(pages).to be_empty
                end
            end
        end

        context 'when the cluster has ben shutdown' do
            it "raises #{described_class::Error::AlreadyShutdown}" do
                subject.shutdown
                expect { subject.queue( job, (proc_to_method {}) ) }.to raise_error described_class::Error::AlreadyShutdown
            end
        end
    end

    describe '#explore' do
        subject { described_class.new }
        let(:url) do
            SCNR::Engine::Utilities.normalize_url( web_server_url_for( :browser ) ) + 'explore'
        end

        context 'when the resource is a' do
            context 'String' do
                it 'loads the URL and explores the DOM' do
                    pages = []

                    subject.explore( url, (proc_to_method do |result|
                        pages << result.page
                    end))
                    subject.wait

                    browser_explore_check_pages pages
                end
            end

            context 'Engine::HTTP::Response' do
                it 'loads it and explores the DOM' do
                    pages = []

                    subject.explore( SCNR::Engine::HTTP::Client.get( url, mode: :sync ), (proc_to_method do |result|
                        pages << result.page
                    end))
                    subject.wait

                    browser_explore_check_pages pages
                end
            end

            context 'Engine::Page' do
                it 'loads it and explores the DOM' do
                    pages = []

                    subject.explore( SCNR::Engine::Page.from_url( url ), (proc_to_method do |result|
                        pages << result.page
                    end))
                    subject.wait

                    browser_explore_check_pages pages
                end
            end
        end
    end

    describe '#trace_taint' do
        context 'when tracing the data-flow' do
            let(:taint) { SCNR::Engine::Utilities.generate_token }
            let(:url) do
                SCNR::Engine::Utilities.normalize_url( web_server_url_for( :taint_tracer ) ) +
                    "/data_trace/user-defined-global-functions?taint=#{taint}"
            end

            context 'when a callback argument is given' do
                it 'sets it as a callback' do
                    pages = []
                    m = (proc_to_method do |result|
                        pages << result.page
                    end)

                    subject.trace_taint( url, { taint: taint }, m )
                    subject.wait

                    browser_pool_job_taint_tracer_data_flow_check_pages  pages
                end
            end

            context 'and the resource is a' do
                context 'String' do
                    it 'loads the URL and traces the taint' do
                        pages = []
                        subject.trace_taint( url, {taint: taint}, (proc_to_method do |result|
                            pages << result.page
                        end))
                        subject.wait

                        browser_pool_job_taint_tracer_data_flow_check_pages  pages
                    end
                end

                context 'Engine::HTTP::Response' do
                    it 'loads it and traces the taint' do
                        pages = []

                        subject.trace_taint( SCNR::Engine::HTTP::Client.get( url, mode: :sync ),
                                              {taint: taint}, (proc_to_method do |result|
                            pages << result.page
                        end))
                        subject.wait

                        browser_pool_job_taint_tracer_data_flow_check_pages  pages
                    end
                end

                context 'Engine::Page' do
                    it 'loads it and traces the taint' do
                        pages = []

                        subject.trace_taint( SCNR::Engine::Page.from_url( url ),
                                              {taint: taint}, (proc_to_method do |result|
                            pages << result.page
                        end))
                        subject.wait

                        browser_pool_job_taint_tracer_data_flow_check_pages  pages
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
                            subject.trace_taint( url,
                                                  {taint: taint,
                                                  injector: injector}, (proc_to_method do |result|
                                pages << result.page
                            end))
                            subject.wait

                            browser_pool_job_taint_tracer_data_flow_with_injector_check_pages  pages
                        end
                    end

                    context 'Engine::HTTP::Response' do
                        it 'loads it and traces the taint' do
                            pages = []
                            subject.trace_taint( SCNR::Engine::HTTP::Client.get( url, mode: :sync ),
                                                  {taint: taint,
                                                  injector: injector}, (proc_to_method do |result|
                                pages << result.page
                            end))
                            subject.wait

                            browser_pool_job_taint_tracer_data_flow_with_injector_check_pages  pages
                        end
                    end

                    context 'Engine::Page' do
                        it 'loads it and traces the taint' do
                            pages = []
                            subject.trace_taint( SCNR::Engine::Page.from_url( url ),
                                                  {taint: taint,
                                                  injector: injector}, (proc_to_method do |result|
                                pages << result.page
                            end))
                            subject.wait

                            browser_pool_job_taint_tracer_data_flow_with_injector_check_pages  pages
                        end
                    end
                end
            end
        end

        context 'when tracing the execution-flow' do
            let(:url) do
                SCNR::Engine::Utilities.normalize_url( web_server_url_for( :taint_tracer ) ) +
                    "debug?input=#{subject.javascript_token}TaintTracer.log_execution_flow_sink()"
            end

            context 'and the resource is a' do
                context 'String' do
                    it 'loads the URL and traces the taint' do
                        pages = []
                        subject.trace_taint( url, (proc_to_method do |result|
                            pages << result.page
                        end))
                        subject.wait

                        browser_pool_job_taint_tracer_execution_flow_check_pages pages
                    end
                end

                context 'Engine::HTTP::Response' do
                    it 'loads it and traces the taint' do
                        pages = []
                        subject.trace_taint( SCNR::Engine::HTTP::Client.get( url, mode: :sync ), (proc_to_method do |result|
                            pages << result.page
                        end))
                        subject.wait

                        browser_pool_job_taint_tracer_execution_flow_check_pages pages
                    end
                end

                context 'Engine::Page' do
                    it 'loads it and traces the taint' do
                        pages = []
                        subject.trace_taint( SCNR::Engine::Page.from_url( url ), (proc_to_method do |result|
                            pages << result.page
                        end))
                        subject.wait

                        browser_pool_job_taint_tracer_execution_flow_check_pages pages
                    end
                end
            end
        end
    end

    describe '#job_done' do
        it 'marks the given job as done' do
            calls = 0
            subject.queue( job, (proc_to_method do
                calls += 1
            end))
            subject.wait

            expect(calls).to be > 1
            expect(subject.job_done?( job )).to eq(true)
        end

        it 'gets called after each job is done' do
            expect(subject).to receive(:job_done).with(job).and_call_original

            q = Queue.new
            subject.queue( job, (proc_to_method { q << nil }))
            q.pop
        end

        it 'increments the .completed_job_count' do
            pre = described_class.completed_job_count

            subject.queue( job, (proc_to_method {}) )
            subject.wait

            expect(described_class.completed_job_count).to be > pre
        end

        it 'adds the job time to the .total_job_time' do
            pre = described_class.total_job_time

            subject.queue( job, (proc_to_method {}))
            subject.wait

            expect(described_class.total_job_time).to be > pre
        end
    end

    describe '#job_done?' do
        context 'when a job has finished' do
            it 'returns true' do
                subject.queue( job, (proc_to_method {}))
                subject.wait

                expect(subject.job_done?( job )).to eq(true)
            end
        end

        context 'when a job is in progress' do
            it 'returns false' do
                subject.queue( job, (proc_to_method {}))

                expect(subject.job_done?( job )).to eq(false)
            end
        end

        context 'when a job has been marked as #never_ending' do
            it 'returns false' do
                job.never_ending = true
                subject.queue( job, (proc_to_method {}))
                subject.wait

                expect(subject.job_done?( job )).to eq(false)
            end
        end

        context 'when the job has not been queued' do
            it "raises #{described_class::Error::JobNotFound}" do
                expect { subject.job_done?( job ) }.to raise_error described_class::Error::JobNotFound
            end
        end
    end

    describe '#wait' do
        it 'waits until the analysis is complete' do
            pages = []

            subject.queue( job, (proc_to_method do |result|
                pages << result.page
            end))

            expect(pages).to be_empty
            expect(subject.done?).to be_falsey
            subject.wait
            expect(subject.done?).to be_truthy
            expect(pages).to be_any
        end

        it 'returns self' do
            expect(subject.wait).to eq(subject)
        end

        context 'when the cluster has ben shutdown' do
            it "raises #{described_class::Error::AlreadyShutdown}" do
                subject.shutdown
                expect { subject.wait }.to raise_error described_class::Error::AlreadyShutdown
            end
        end
    end

    describe '#done?' do
        context 'while analysis is in progress' do
            it 'returns false' do
                subject.queue( job, (proc_to_method {}))
                expect(subject.done?).to be_falsey
            end
        end

        context 'when analysis has completed' do
            it 'returns true' do
                subject.queue( job, (proc_to_method {}))
                expect(subject.done?).to be_falsey
                subject.wait
                expect(subject.done?).to be_truthy
            end
        end

        context 'when the cluster has been shutdown' do
            it "raises #{described_class::Error::AlreadyShutdown}" do
                subject.shutdown
                expect { subject.done? }.to raise_error described_class::Error::AlreadyShutdown
            end
        end
    end

end
