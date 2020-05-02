require 'spec_helper'

class SCNR::Engine::BrowserCluster::Worker
    def observer_count_for( event )
        observers_for( event ).size
    end
end

describe SCNR::Engine::BrowserCluster::Worker do

    let(:browser_cluster) { SCNR::Engine::BrowserCluster.new }
    let(:url) { SCNR::Engine::Utilities.normalize_url( web_server_url_for( :browser ) ) }
    let(:job) do
        SCNR::Engine::BrowserCluster::Jobs::DOMExploration.new(
            resource: SCNR::Engine::Page.from_url( url + 'explore', mode: :sync )
        )
    end
    let(:custom_job) { Factory[:custom_job] }
    let(:sleep_job) { Factory[:sleep_job] }
    let(:options) { {} }
    let(:subject) { browser_cluster.workers.first }

    describe '#initialize' do
        describe ':max_time_to_live' do
            context 'when given' do
                subject { described_class.new( max_time_to_live: 10 ) }

                it 'sets how many jobs should be run before respawning' do
                    expect(subject.max_time_to_live).to eq(10)
                end
            end

            it "defaults to #{SCNR::Engine::OptionGroups::BrowserCluster}#worker_time_to_live" do
                SCNR::Engine::Options.browser_cluster.worker_time_to_live = 5
                expect(subject.max_time_to_live).to eq(5)
            end
        end
    end

    describe '#run_job' do
        it 'processes jobs from #master' do
            expect(subject).to receive(:run_job).with(custom_job)
            browser_cluster.queue( custom_job, (proc_to_method {}))
            sleep 1
        end

        it 'assigns #job to the running job' do
            job = nil
            browser_cluster.queue( custom_job, (proc_to_method do
                job = subject.job
            end))
            browser_cluster.wait
            expect(job).to eq(custom_job)
        end

        it 'assigns #parse_profile' do
            pp = SCNR::Engine::Browser::ParseProfile.new

            profile = nil
            custom_job.parse_profile = pp
            browser_cluster.queue( custom_job, (proc_to_method do
                profile = subject.parse_profile
            end))
            browser_cluster.wait
            expect(profile).to eq(pp)
        end

        context 'before running the job' do
            context 'when the engine is dead' do
                it 'spawns a new one' do
                    SCNR::Engine::Processes::Manager.kill subject.engine.pid

                    dead_lifeline_pid = subject.engine.lifeline_pid
                    dead_browser_pid  = subject.engine.pid

                    browser_cluster.queue( custom_job, (proc_to_method {}))
                    browser_cluster.wait

                    expect(subject.engine.pid).not_to eq(dead_browser_pid)
                    expect(subject.engine.lifeline_pid).not_to eq(dead_lifeline_pid)

                    expect(SCNR::Engine::Processes::Manager.alive?( subject.engine.lifeline_pid )).to be_truthy
                    expect(SCNR::Engine::Processes::Manager.alive?( subject.engine.pid )).to be_truthy
                end
            end

            context 'when the lifeline is dead' do
                it 'spawns a new one' do
                    SCNR::Engine::Processes::Manager << subject.engine.pid
                    SCNR::Engine::Processes::Manager.kill subject.engine.lifeline_pid

                    dead_lifeline_pid = subject.engine.lifeline_pid
                    dead_browser_pid  = subject.engine.pid

                    browser_cluster.queue( custom_job, (proc_to_method {}))
                    browser_cluster.wait

                    expect(subject.engine.pid).not_to eq(dead_browser_pid)
                    expect(subject.engine.lifeline_pid).not_to eq(dead_lifeline_pid)

                    expect(SCNR::Engine::Processes::Manager.alive?( subject.engine.lifeline_pid )).to be_truthy
                    expect(SCNR::Engine::Processes::Manager.alive?( subject.engine.pid )).to be_truthy
                end
            end
        end

        context 'when a job fails' do
            it 'ignores it' do
                allow(custom_job).to receive(:configure_and_run){ raise 'stuff' }
                expect(subject.run_job( custom_job )).to be_truthy
            end

            context 'Selenium::WebDriver::Error::WebDriverError' do
                it 'respawns' do
                    expect(custom_job).to receive(:configure_and_run) do
                        raise Selenium::WebDriver::Error::WebDriverError
                    end

                    watir = subject.watir
                    pid   = subject.engine.pid

                    subject.run_job( custom_job )

                    expect(watir).not_to eq(subject.watir)
                    expect(pid).not_to eq(subject.engine.pid)
                end
            end
        end

        context 'when the job finishes' do
            let(:page) { SCNR::Engine::Page.from_url(url) }

            it "clears the #{SCNR::Engine::Browser::Javascript}#taint" do
                subject.javascript.taint = 'stuff'

                browser_cluster.queue( custom_job, (proc_to_method {}))
                browser_cluster.wait

                expect(subject.javascript.taint).to be_nil
            end

            it 'clears #preloads' do
                subject.preload page
                expect(subject.preloads).to be_any

                browser_cluster.queue( custom_job, (proc_to_method {}))
                browser_cluster.wait

                expect(subject.preloads).to be_empty
            end

            it 'clears #captured_pages' do
                subject.captured_pages << page

                browser_cluster.queue( custom_job, (proc_to_method {}))
                browser_cluster.wait

                expect(subject.captured_pages).to be_empty
            end

            it 'clears #page_snapshots' do
                subject.page_snapshots << page

                browser_cluster.queue( custom_job, (proc_to_method {}))
                browser_cluster.wait

                expect(subject.page_snapshots).to be_empty
            end

            it 'clears #page_snapshots_with_sinks' do
                subject.page_snapshots_with_sinks << page

                browser_cluster.queue( custom_job, (proc_to_method {}))
                browser_cluster.wait

                expect(subject.page_snapshots_with_sinks).to be_empty
            end

            it 'clears #on_new_page callbacks' do
                subject.on_new_page{}

                browser_cluster.queue( custom_job, (proc_to_method {}))
                browser_cluster.wait

                expect(subject.observer_count_for(:on_new_page)).to eq(0)
            end

            it 'clears #on_new_page_with_sink callbacks' do
                subject.on_new_page_with_sink{}

                browser_cluster.queue( custom_job, (proc_to_method {}))
                browser_cluster.wait

                expect(subject.observer_count_for(:on_new_page_with_sink)).to eq(0)
            end

            it 'clears #on_response callbacks' do
                subject.on_response{}

                browser_cluster.queue( custom_job, (proc_to_method {}))
                browser_cluster.wait

                expect(subject.observer_count_for(:on_response)).to eq(0)
            end

            it 'clears #on_fire_event callbacks' do
                subject.on_fire_event{}

                browser_cluster.queue( custom_job, (proc_to_method {}))
                browser_cluster.wait

                expect(subject.observer_count_for(:on_fire_event)).to eq(0)
            end

            it 'removes #job' do
                browser_cluster.queue( custom_job, (proc_to_method {}))
                browser_cluster.wait
                expect(subject.job).to be_nil
            end

            it 'decrements #time_to_live' do
                browser_cluster.queue( custom_job, (proc_to_method {}))
                browser_cluster.wait
                expect(subject.time_to_live).to eq(subject.max_time_to_live - 1)
            end

            it 'sets Job#time' do
                browser_cluster.queue( custom_job, (proc_to_method {}))
                browser_cluster.wait
                expect(custom_job.time).to be > 0
            end

            context 'when #time_to_live reaches 0' do
                before do
                    SCNR::Engine::Options.browser_cluster.worker_time_to_live = 1
                end

                it 'respawns the browser' do
                    subject.max_time_to_live = 1

                    watir = subject.watir
                    pid   = subject.engine.pid

                    browser_cluster.queue( custom_job, (proc_to_method {}))
                    browser_cluster.wait

                    expect(watir).not_to eq(subject.watir)
                    expect(pid).not_to eq(subject.engine.pid)
                end
            end
        end

        context 'when a Selenium request takes more than OptionGroup::BrowserCluster#job_timeout' do
            before do
                allow(subject).to receive(:trigger_events) { raise Timeout::Error }
            end

            it "retries #{described_class::TRIES} times" do
                expect(subject).to receive(:reset).at_least(described_class::TRIES).times

                browser_cluster.queue( job, (proc_to_method {}))
                browser_cluster.wait
            end

            context "after #{described_class::TRIES} tries" do
                it 'sets Job#time' do
                    browser_cluster.queue( job, (proc_to_method {}))
                    browser_cluster.wait

                    expect(job.time).to be > 0
                end

                it 'sets Job#timed_out?' do
                    browser_cluster.queue( job, (proc_to_method {}))
                    browser_cluster.wait

                    expect(job).to be_timed_out
                end

                it 'increments the BrowserCluster timeout count' do
                    time_out_count = SCNR::Engine::BrowserCluster.statistics[:time_out_count]

                    browser_cluster.queue( job, (proc_to_method {}))
                    browser_cluster.wait

                    expect(SCNR::Engine::BrowserCluster.statistics[:time_out_count]).to eq time_out_count+1
                end
            end
        end
    end

end
