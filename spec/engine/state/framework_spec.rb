require 'spec_helper'

describe SCNR::Engine::State::Framework do

    subject { described_class.new }
    before(:each) { subject.clear }

    let(:page) { Factory[:page] }
    let(:element) { Factory[:link] }
    let(:url) { page.url }
    let(:dump_directory) do
        "#{Dir.tmpdir}/framework-#{SCNR::Engine::Utilities.generate_token}"
    end

    describe '#status_messages' do
        it 'returns the assigned status messages' do
            message = 'Hey!'
            subject.set_status_message message
            expect(subject.status_messages).to eq([message])
        end

        context 'by defaults' do
            it 'returns an empty array' do
                expect(subject.status_messages).to eq([])
            end
        end
    end

    describe '#set_status_message' do
        it 'sets the #status_messages to the given message' do
            message = 'Hey!'
            subject.set_status_message message
            subject.set_status_message message
            expect(subject.status_messages).to eq([message])
        end
    end

    describe '#add_status_message' do
        context 'when given a message of type' do
            context 'String' do
                it 'pushes it to #status_messages' do
                    message = 'Hey!'
                    subject.add_status_message message
                    subject.add_status_message message
                    expect(subject.status_messages).to eq([message, message])
                end
            end

            context 'Symbol' do
                context 'and it exists in #available_status_messages' do
                    it 'pushes the associated message to #status_messages' do
                        subject.add_status_message :suspending
                        expect(subject.status_messages).to eq([subject.available_status_messages[:suspending]])
                    end
                end

                context 'and it does not exist in #available_status_messages' do
                    it "raises #{described_class::Error::InvalidStatusMessage}" do
                        expect do
                            subject.add_status_message :stuff
                        end.to raise_error described_class::Error::InvalidStatusMessage
                    end
                end

                context 'when given sprintf arguments' do
                    it 'uses them to fill in the placeholders' do
                        location = '/blah/stuff.ses'
                        subject.add_status_message :snapshot_location, location
                        expect(subject.status_messages).to eq([subject.available_status_messages[:snapshot_location] % location])
                    end
                end
            end
        end
    end

    describe '#statistics' do
        let(:statistics) { subject.statistics }

        it 'includes #rpc statistics' do
            expect(statistics[:rpc]).to eq(subject.rpc.statistics)
        end

        it 'includes #audited_page_count' do
            subject.audited_page_count += 1
            expect(statistics[:audited_page_count]).to eq(subject.audited_page_count)
        end

        it 'includes amount of #browser_skip_states' do
            set = SCNR::Engine::Support::Filter::Set.new
            set << 1 << 2 << 3
            subject.update_browser_skip_states( set )

            expect(statistics[:browser_states]).to eq(subject.browser_skip_states.size)
        end
    end

    describe '#page_queue_filter' do
        it "returns an instance of #{SCNR::Engine::Support::Filter::Set}" do
            expect(subject.page_queue_filter).to be_kind_of SCNR::Engine::Support::Filter::Set
        end
    end

    describe '#url_queue_filter' do
        it "returns an instance of #{SCNR::Engine::Support::Filter::Set}" do
            expect(subject.url_queue_filter).to be_kind_of SCNR::Engine::Support::Filter::Set
        end
    end

    describe '#rpc' do
        it "returns an instance of #{described_class::RPC}" do
            expect(subject.rpc).to be_kind_of described_class::RPC
        end
    end

    describe '#element_checked?' do
        context 'when an element has already been checked' do
            it 'returns true' do
                subject.element_pre_check_filter << element
                expect(subject.element_checked?( element )).to be_truthy
            end
        end

        context 'when an element has not been checked' do
            it 'returns false' do
                expect(subject.element_checked?( element )).to be_falsey
            end
        end
    end

    describe '#element_checked' do
        it 'marks an element as checked' do
            subject.element_checked element
            expect(subject.element_checked?( element )).to be_truthy
        end
    end

    describe '#dom_browser_analyzed?' do
        context 'when a DOM has already been seen' do
            it 'returns true' do
                subject.dom_analysis_filter << page.dom
                expect(subject.dom_browser_analyzed?( page.dom )).to be_truthy
            end
        end

        context 'when a DOM has not been seen' do
            it 'returns false' do
                expect(subject.dom_browser_analyzed?( page.dom )).to be_falsey
            end
        end
    end

    describe '#dom_browser_analyzed' do
        context 'when the given DOM has been marked as seen' do
            it 'returns true' do
                subject.dom_browser_analyzed page.dom
                expect(subject.dom_browser_analyzed?( page.dom )).to be_truthy
            end
        end

        context 'when the given DOM has not been marked as seen' do
            it 'returns false' do
                expect(subject.dom_browser_analyzed?( page.dom )).to be_falsey
            end
        end
    end

    describe '#page_seen?' do
        context 'when a page has already been seen' do
            it 'returns true' do
                subject.page_queue_filter << page
                expect(subject.page_seen?( page )).to be_truthy
            end
        end

        context 'when a page has not been seen' do
            it 'returns false' do
                expect(subject.page_seen?( page )).to be_falsey
            end
        end
    end

    describe '#page_seen' do
        context 'when the given page has been marked as seen' do
            it 'returns true' do
                subject.page_seen page
                expect(subject.page_seen?( page )).to be_truthy
            end
        end

        context 'when the given page has not been marked as seen' do
            it 'returns false' do
                expect(subject.page_seen?( page )).to be_falsey
            end
        end
    end

    describe '#page_paths_seen?' do
        context 'when a page has already been seen' do
            it 'returns true' do
                subject.page_paths_filter << page
                expect(subject.page_paths_seen?( page )).to be_truthy
            end
        end

        context 'when a page has not been seen' do
            it 'returns false' do
                expect(subject.page_paths_seen?( page )).to be_falsey
            end
        end
    end

    describe '#page_paths_seen' do
        context 'when the given page has been marked as seen' do
            it 'returns true' do
                subject.page_paths_seen page
                expect(subject.page_paths_seen?( page )).to be_truthy
            end
        end

        context 'when the given page has not been marked as seen' do
            it 'returns false' do
                expect(subject.page_paths_seen?( page )).to be_falsey
            end
        end
    end

    describe '#url_seen?' do
        context 'when a URL has already been seen' do
            it 'returns true' do
                subject.url_queue_filter << url
                expect(subject.url_seen?( url )).to be_truthy
            end
        end

        context 'when a page has not been seen' do
            it 'returns false' do
                expect(subject.url_seen?( url )).to be_falsey
            end
        end
    end

    describe '#url_seen' do
        context 'when the given URL has been marked as seen' do
            it 'returns true' do
                subject.url_seen url
                expect(subject.url_seen?( url )).to be_truthy
            end
        end

        context 'when the given URL has not been marked as seen' do
            it 'returns false' do
                expect(subject.url_seen?( url )).to be_falsey
            end
        end
    end

    describe '#running=' do
        it 'sets #running' do
            expect(subject.running).to be_falsey

            subject.running = true
            expect(subject.running).to be_truthy
        end
    end

    describe '#running?' do
        context 'when #running is true' do
            it 'returns true' do
                subject.running = true
                expect(subject).to be_running
            end
        end

        context 'when #running is false' do
            it 'returns false' do
                subject.running = false
                expect(subject).not_to be_running
            end
        end
    end

    describe '#scanning?' do
        context 'when the status is set to :scanning' do
            it 'returns true' do
                subject.status = :scanning
                expect(subject).to be_scanning
            end
        end

        context 'when the status is not set to :scanning' do
            it 'returns false' do
                expect(subject).not_to be_scanning
            end
        end
    end

    describe '#suspend' do
        context 'when #running?' do
            before(:each) { subject.running = true }

            it 'sets the #status to :suspending' do
                subject.suspend
                expect(subject.status).to eq(:suspending)
            end

            it 'sets the status message to :suspending' do
                subject.suspend
                expect(subject.status_messages).to eq(
                    [subject.available_status_messages[:suspending]]
                )
            end

            it 'returns true' do
                expect(subject.suspend).to be_truthy
            end

            context 'when already #suspending?' do
                it 'returns false' do
                    expect(subject.suspend).to be_truthy
                    expect(subject).to be_suspending
                    expect(subject.suspend).to be_falsey
                end
            end

            context 'when already #suspended?' do
                it 'returns false' do
                    expect(subject.suspend).to be_truthy
                    subject.suspended
                    expect(subject).to be_suspended

                    expect(subject.suspend).to be_falsey
                end
            end

            context 'when #pausing?' do
                it "raises #{described_class::Error::StateNotSuspendable}" do
                    subject.pause

                    expect{ subject.suspend }.to raise_error described_class::Error::StateNotSuspendable
                end
            end

            context 'when #paused?' do
                it "raises #{described_class::Error::StateNotSuspendable}" do
                    subject.pause
                    subject.paused

                    expect{ subject.suspend }.to raise_error described_class::Error::StateNotSuspendable
                end
            end
        end

        context 'when not #running?' do
            it "raises #{described_class::Error::StateNotSuspendable}" do
                expect{ subject.suspend }.to raise_error described_class::Error::StateNotSuspendable
            end
        end
    end

    describe '#suspended' do
        it 'sets the #status to :suspended' do
            subject.suspended
            expect(subject.status).to eq(:suspended)
        end
    end

    describe '#suspended?' do
        context 'when #suspended' do
            it 'returns true' do
                subject.suspended
                expect(subject).to be_suspended
            end
        end

        context 'when not #suspended' do
            it 'returns false' do
                expect(subject).not_to be_suspended
            end
        end
    end

    describe '#suspending?' do
        before(:each) { subject.running = true }

        context 'while suspending' do
            it 'returns true' do
                subject.suspend
                expect(subject).to be_suspending
            end
        end

        context 'while not suspending' do
            it 'returns false' do
                expect(subject).not_to be_suspending

                subject.suspend
                subject.suspended
                expect(subject).not_to be_suspending
            end
        end
    end

    describe '#suspend?' do
        before(:each) { subject.running = true }

        context 'when a #suspend signal is in place' do
            it 'returns true' do
                subject.suspend
                expect(subject).to be_suspend
            end
        end

        context 'when a #suspend signal is not in place' do
            it 'returns false' do
                expect(subject).not_to be_suspend

                subject.suspend
                subject.suspended
                expect(subject).not_to be_suspend
            end
        end
    end

    describe '#abort' do
        context 'when #running?' do
            before(:each) { subject.running = true }

            it 'sets the #status to :aborting' do
                subject.abort
                expect(subject.status).to eq(:aborting)
            end

            it 'sets the status message to :aborting' do
                subject.abort
                expect(subject.status_messages).to eq(
                    [subject.available_status_messages[:aborting]]
                )
            end

            it 'returns true' do
                expect(subject.abort).to be_truthy
            end

            context 'when already #aborting?' do
                it 'returns false' do
                    expect(subject.abort).to be_truthy
                    expect(subject).to be_aborting
                    expect(subject.abort).to be_falsey
                end
            end

            context 'when already #aborted?' do
                it 'returns false' do
                    expect(subject.abort).to be_truthy
                    subject.aborted
                    expect(subject).to be_aborted

                    expect(subject.abort).to be_falsey
                end
            end
        end

        context 'when not #running?' do
            it "raises #{described_class::Error::StateNotAbortable}" do
                expect{ subject.abort }.to raise_error described_class::Error::StateNotAbortable
            end
        end
    end

    describe '#done?' do
        context 'when #status is :done' do
            it 'returns true' do
                subject.status = :done
                expect(subject).to be_done
            end
        end

        context 'when not done' do
            it 'returns false' do
                expect(subject).not_to be_done
            end
        end
    end

    describe '#aborted' do
        it 'sets the #status to :aborted' do
            subject.aborted
            expect(subject.status).to eq(:aborted)
        end
    end

    describe '#aborted?' do
        context 'when #aborted' do
            it 'returns true' do
                subject.aborted
                expect(subject).to be_aborted
            end
        end

        context 'when not #aborted' do
            it 'returns false' do
                expect(subject).not_to be_aborted
            end
        end
    end

    describe '#aborting?' do
        before(:each) { subject.running = true }

        context 'while aborting' do
            it 'returns true' do
                subject.abort
                expect(subject).to be_aborting
            end
        end

        context 'while not aborting' do
            it 'returns false' do
                expect(subject).not_to be_aborting

                subject.abort
                subject.aborted
                expect(subject).not_to be_aborting
            end
        end
    end

    describe '#abort?' do
        before(:each) { subject.running = true }

        context 'when a #abort signal is in place' do
            it 'returns true' do
                subject.abort
                expect(subject).to be_abort
            end
        end

        context 'when a #abort signal is not in place' do
            it 'returns false' do
                expect(subject).not_to be_abort

                subject.abort
                subject.aborted
                expect(subject).not_to be_abort
            end
        end
    end

    describe '#timed_out' do
        it 'sets the #status to :timed_out' do
            subject.timed_out
            expect(subject.status).to eq(:timed_out)
        end
    end

    describe '#timed_out?' do
        context 'when a #timed_out signal is in place' do
            it 'returns true' do
                subject.timed_out
                expect(subject).to be_timed_out
            end
        end

        context 'when a #timed_out signal is not in place' do
            it 'returns false' do
                expect(subject).not_to be_timed_out
            end
        end
    end

    describe '#pause' do
        context 'when #running?' do
            before(:each) { subject.running = true }

            it 'sets the #status to :pausing' do
                subject.pause
                expect(subject.status).to eq(:pausing)
            end

            it 'returns true' do
                expect(subject.pause).to be_truthy
            end
        end

        context 'when not #running?' do
            before(:each) { subject.running = false }

            it 'sets the #status directly to :paused' do
                t = Thread.new do
                    sleep 1
                    subject.paused
                end

                time = Time.now
                subject.pause
                expect(subject.status).to eq(:paused)
                expect(Time.now - time).to be < 1
                t.join
            end
        end
    end

    describe '#paused' do
        it 'sets the #status to :paused' do
            subject.paused
            expect(subject.status).to eq(:paused)
        end
    end

    describe '#pausing?' do
        before(:each) { subject.running = true }

        context 'while pausing' do
            it 'returns true' do
                subject.pause
                expect(subject).to be_pausing
            end
        end

        context 'while not pausing' do
            it 'returns false' do
                expect(subject).not_to be_pausing

                subject.pause
                subject.paused
                expect(subject).not_to be_pausing
            end
        end
    end

    describe '#pause?' do
        context 'when a #pause signal is in place' do
            it 'returns true' do
                subject.pause
                expect(subject).to be_pause
            end
        end

        context 'when a #pause signal is not in place' do
            it 'returns false' do
                expect(subject).not_to be_pause

                subject.pause
                subject.paused
                subject.resume
                expect(subject).not_to be_pause
            end
        end
    end

    describe '#resume' do
        before(:each) { subject.running = true }

        it 'restores the previous #status' do
            subject.status = :my_status

            subject.pause
            subject.paused
            expect(subject.status).to be :paused

            subject.resume
            expect(subject.status).to be :my_status
        end

        context 'when called before a #pause signal has been sent' do
            it '#pause? returns false' do
                subject.pause
                subject.resume
                expect(subject).not_to be_pause
            end

            it '#paused? returns false' do
                subject.pause
                subject.resume
                expect(subject).not_to be_paused
            end
        end

        context 'when there are no more signals' do
            it 'returns true' do
                subject.pause
                subject.paused

                expect(subject.resume).to be_truthy
            end
        end
    end

    describe '#browser_skip_states' do
        it "returns a #{SCNR::Engine::Support::Filter::Set}" do
            expect(subject.browser_skip_states).to be_kind_of SCNR::Engine::Support::Filter::Set
        end
    end

    describe '#update_browser_skip_states' do
        it 'updates #browser_skip_states' do
            expect(subject.browser_skip_states).to be_empty

            set = SCNR::Engine::Support::Filter::Set.new
            set << 1 << 2 << 3
            subject.update_browser_skip_states( set )
            expect(subject.browser_skip_states).to eq(set)
        end
    end

    describe '#dump' do
        it 'stores #rpc to disk' do
            subject.dump( dump_directory )
            expect(described_class::RPC.load( "#{dump_directory}/rpc" )).to be_kind_of described_class::RPC
        end

        it 'stores #dom_analysis_filter to disk' do
            subject.dom_analysis_filter << page.dom

            subject.dump( dump_directory )

            d = SCNR::Engine::Support::Filter::Set.new( hasher: :playable_transitions_hash )
            d << page.dom
            expect(Marshal.load( IO.read( "#{dump_directory}/dom_analysis_filter" ) )).to eq(d)
        end

        it 'stores #page_queue_filter to disk' do
            subject.page_queue_filter << page

            subject.dump( dump_directory )

            d = SCNR::Engine::Support::Filter::Set.new(hasher: :persistent_hash )
            d << page
            expect(Marshal.load( IO.read( "#{dump_directory}/page_queue_filter" ) )).to eq(d)
        end

        it 'stores #page_paths_filter to disk' do
            subject.page_paths_filter << page

            subject.dump( dump_directory )

            d = SCNR::Engine::Support::Filter::Set.new(hasher: :paths_hash )
            d << page
            expect(Marshal.load( IO.read( "#{dump_directory}/page_paths_filter" ) )).to eq(d)
        end

        it 'stores #url_queue_filter to disk' do
            subject.url_queue_filter << url

            subject.dump( dump_directory )

            d = SCNR::Engine::Support::Filter::Set.new(hasher: :persistent_hash )
            d << url
            expect(Marshal.load( IO.read( "#{dump_directory}/url_queue_filter" ) )).to eq(d)
        end

        it 'stores #browser_skip_states to disk' do
            stuff = 'stuff'
            subject.browser_skip_states << stuff

            subject.dump( dump_directory )

            set = SCNR::Engine::Support::Filter::Set.new( hasher: :persistent_hash )
            set << stuff

            expect(Marshal.load( IO.read( "#{dump_directory}/browser_skip_states" ) )).to eq(set)
        end
    end

    describe '.load' do
        it 'loads #rpc from disk' do
            subject.dump( dump_directory )
            expect(described_class.load( dump_directory ).rpc).to be_kind_of described_class::RPC
        end

        it 'loads #element_pre_check_filter from disk' do
            subject.element_pre_check_filter << element

            subject.dump( dump_directory )

            d = SCNR::Engine::Support::Filter::Set.new(hasher: :coverage_and_trace_hash )
            d << element

            expect(described_class.load( dump_directory ).element_pre_check_filter).to eq(d)
        end

        it 'loads #dom_analysis_filter from disk' do
            subject.dom_analysis_filter << page.dom

            subject.dump( dump_directory )

            set = SCNR::Engine::Support::Filter::Set.new(hasher: :playable_transitions_hash )
            set << page.dom
            expect(described_class.load( dump_directory ).dom_analysis_filter).to eq(set)
        end

        it 'loads #page_queue_filter from disk' do
            subject.page_queue_filter << page

            subject.dump( dump_directory )

            set = SCNR::Engine::Support::Filter::Set.new(hasher: :persistent_hash )
            set << page
            expect(described_class.load( dump_directory ).page_queue_filter).to eq(set)
        end

        it 'loads #page_paths_filter from disk' do
            subject.page_paths_filter << page

            subject.dump( dump_directory )

            set = SCNR::Engine::Support::Filter::Set.new(hasher: :paths_hash )
            set << page
            expect(described_class.load( dump_directory ).page_paths_filter).to eq(set)
        end

        it 'loads #url_queue_filter from disk' do
            subject.url_queue_filter << url
            expect(subject.url_queue_filter).to be_any

            subject.dump( dump_directory )

            set = SCNR::Engine::Support::Filter::Set.new(hasher: :persistent_hash )
            set << url
            expect(described_class.load( dump_directory ).url_queue_filter).to eq(set)
        end

        it 'loads #browser_skip_states from disk' do
            stuff = 'stuff'
            subject.browser_skip_states << stuff

            subject.dump( dump_directory )

            set = SCNR::Engine::Support::Filter::Set.new(hasher: :persistent_hash)
            set << stuff
            expect(described_class.load( dump_directory ).browser_skip_states).to eq(set)
        end
    end

    describe '#clear' do
        %w(rpc element_pre_check_filter browser_skip_states page_queue_filter
            url_queue_filter page_paths_filter dom_analysis_filter
        ).each do |method|
            it "clears ##{method}" do
                expect(subject.send(method)).to receive(:clear)
                subject.clear
            end
        end

        it 'sets #running to false' do
            subject.running = true
            subject.clear
            expect(subject).not_to be_running
        end
    end
end
