require 'spec_helper'

class MockBrowserPool
    attr_reader :result

    def handle_job_result( result )
        @result = result
    end
end

class MockWorker
    def master
        @master ||= MockBrowserPool.new
    end
end

class JobTest < SCNR::Engine::BrowserPool::Job
    include RSpec::Matchers

    def ran?
        !!@ran
    end

    def run
        expect(browser.class).to eq MockWorker
        @ran = true
    end
end

class JobConfigureAndRunTest < JobTest
    def run
        expect(browser.class).to eq MockWorker
        super
    end
end

class JobSaveResultTest < JobTest
    class Result < SCNR::Engine::BrowserPool::Job::Result
        attr_accessor :my_data
    end

    def run
        val = 'stuff'
        save_result my_data: val

        result = browser.master.result
        expect(result.job.id).to eq self.id
        expect(result.my_data).to eq val

        super
    end
end

class JobCleanCopyTest < JobTest
    def run
        expect(browser.class).to eq MockWorker

        copy = self.clean_copy
        expect(copy.browser).to eq nil
        expect(copy.id).to eq self.id

        expect(browser.class).to eq MockWorker

        super
    end
end

class JobDupTest < JobTest
    attr_accessor :my_data

    def initialize( options )
        super options
        @my_data = options.delete( :my_data )
    end
end

class JobForwardTest < JobDupTest
end

class JobForwardAsTest < JobForwardTest
end

describe SCNR::Engine::BrowserPool::Job do
    let(:browser_pool) { MockBrowserPool.new }
    let(:worker) { MockWorker.new }
    let(:args) { [1, 2] }

    describe '#parse_profile' do
        it "returns the #{SCNR::Engine::Browser::ParseProfile}" do
            pp = SCNR::Engine::Browser::ParseProfile.new

            j = described_class.new(
                parse_profile: pp
            )

            expect( j.parse_profile ).to be pp
        end
    end

    describe '#id' do
        it 'gets incremented with each initialization' do
            id = nil
            10.times do |i|
                id = described_class.new.id
                next if i == 0

                expect(described_class.new.id).to eq(id + 1)
            end
        end
    end

    describe '#never_ending?' do
        subject { JobTest.new }

        context 'when #never_ending is' do
            context 'true' do
                it 'returns true' do
                    subject.never_ending = true
                    expect(subject.never_ending?).to be_truthy
                end
            end

            context 'false' do
                it 'returns false' do
                    subject.never_ending = false
                    expect(subject.never_ending?).to be_falsey
                end
            end

            context 'nil' do
                it 'returns false' do
                    expect(subject.never_ending?).to be_falsey
                end
            end
        end
    end

    describe '#configure_and_run' do
        subject { JobConfigureAndRunTest.new }

        it 'sets #browser' do
            subject.configure_and_run( worker )
        end

        it 'calls #run' do
            expect(subject.ran?).to be_falsey
            subject.configure_and_run( worker )
            expect(subject.ran?).to be_truthy
        end

        it 'removes #browser' do
            expect(subject.ran?).to be_falsey
            subject.configure_and_run( worker )
            expect(subject.browser).to be_nil
            expect(subject.ran?).to be_truthy
        end
    end

    describe '#save_result' do
        subject { JobSaveResultTest.new }

        it 'forwards the result to the BrowserPool' do
            expect(subject.ran?).to be_falsey
            subject.configure_and_run( worker )
            expect(subject.ran?).to be_truthy
        end
    end

    describe '#clean_copy' do
        subject { JobCleanCopyTest.new }

        it 'clears #skip_states' do
            subject.skip_states << '1'
            expect(subject.clean_copy.skip_states).to be_empty
        end
    end

    describe '#dup' do
        subject { JobDupTest.new( never_ending: true, my_data: 'stuff', args: args, category: :stuff ) }

        it 'copies the Job' do
            expect(subject.my_data).to eq('stuff')

            dup = subject.dup
            expect(dup.my_data).to eq('stuff')
            expect(dup.never_ending?).to eq(true)
        end

        it 'preserves #time' do
            subject.time = 10
            expect(subject.time).to eq 10

            dup = subject.dup
            expect(dup.time).to eq 10
        end

        it 'preserves #category' do
            dup = subject.dup
            expect(dup.category).to eq :stuff
        end

        it 'dups #skip_states' do
            subject.skip_states << '1'

            dup = subject.dup
            expect(dup.skip_states).to eq subject.skip_states
            expect(dup.skip_states.object_id).to_not eq subject.skip_states.object_id
        end

        it 'preserves #timed_out' do
            subject.timed_out! 10
            expect(subject.time).to eq 10
            expect(subject).to be_timed_out

            dup = subject.dup
            expect(dup.time).to eq 10
            expect(subject).to be_timed_out
        end

        it 'preserves #args' do
            expect(subject.args).to eq args

            dup = subject.dup
            expect(dup.args).to eq args
        end
    end

    describe '#forward' do
        subject { JobForwardTest.new( args: args, my_data: 'stuff', category: :stuff ) }

        it 'creates a new Job with the same #id' do
            id = subject.id
            expect(subject.forward.id).to eq(id)
        end

        it 'creates a new Job with the same #never_ending' do
            expect(subject.forward.never_ending?).to be_falsey

            job = JobForwardTest.new( never_ending: true, my_data: 'stuff' )
            expect(job.never_ending?).to be_truthy
            expect(job.forward.never_ending?).to be_truthy

            job = JobForwardTest.new( never_ending: false, my_data: 'stuff' )
            expect(job.never_ending?).to be_falsey
            expect(job.forward.never_ending?).to be_falsey
        end

        it 'does not preserve arbitrary data' do
            expect(subject.forward.my_data).to be_nil
        end

        it 'preserves #category' do
            expect(subject.category).to eq :stuff
        end

        it 'preserves #skip_states' do
            subject.skip_states << '1'

            forwarded = subject.forward
            expect(forwarded.skip_states).to eq subject.skip_states
            expect(forwarded.skip_states.object_id).to eq subject.skip_states.object_id
        end

        it 'preserves #args' do
            expect(subject.forward.args).to eq args
        end

        context 'when options are given' do
            it 'sets initialization options' do
                expect(subject.forward( my_data: 'stuff2' ).my_data).to eq('stuff2')
            end
        end
    end

    describe '#forward_as' do
        subject { JobForwardTest.new( args: args, my_data: 'stuff', category: :stuff  ) }

        it 'creates a new Job type with a new #id' do
            expect(subject).not_to be_kind_of JobForwardAsTest

            id = subject.id

            forwarded = subject.forward_as( JobForwardAsTest )

            expect(forwarded.id).to_not eq(id)
            expect(forwarded).to be_kind_of JobForwardAsTest
        end

        it 'creates a new Job with the same #never_ending' do
            expect(subject.forward_as( JobForwardAsTest ).never_ending?).to be_falsey

            job = JobForwardTest.new( never_ending: true, my_data: 'stuff' )
            expect(job.never_ending?).to be_truthy
            expect(job.forward_as( JobForwardAsTest ).never_ending?).to be_truthy

            job = JobForwardTest.new( never_ending: false, my_data: 'stuff' )
            expect(job.never_ending?).to be_falsey
            expect(job.forward_as( JobForwardAsTest ).never_ending?).to be_falsey
        end

        it 'does not preserve arbitrary existing data' do
            expect(subject).not_to be_kind_of JobForwardAsTest

            forwarded = subject.forward_as( JobForwardAsTest )

            expect(forwarded.my_data).to be_nil
            expect(forwarded).to be_kind_of JobForwardAsTest
        end

        it 'preserves #category' do
            forwarded = subject.forward_as( JobForwardAsTest )
            expect(forwarded.category).to eq :stuff
        end

        it 'clears #skip_states' do
            subject.skip_states << '1'

            forwarded = subject.forward_as( JobForwardAsTest )
            expect(forwarded.skip_states).to be_empty
        end

        it 'preserves #args' do
            expect(subject.forward.args).to eq args
        end

        context 'when options are given' do
            it 'sets initialization options' do
                expect(subject).not_to be_kind_of JobForwardAsTest

                forwarded = subject.forward_as( JobForwardAsTest, my_data: 'stuff2' )

                expect(forwarded.my_data).to eq('stuff2')
                expect(forwarded).to be_kind_of JobForwardAsTest
            end
        end
    end

end
