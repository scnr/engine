require 'spec_helper'

describe SCNR::Engine::State::BrowserCluster do

    subject { described_class.new }
    let(:dump_directory) do
        "#{Dir.tmpdir}/browser-cluster-#{SCNR::Engine::Utilities.generate_token}"
    end

    %w(queued_job_count completed_job_count time_out_count).each do |type|
        describe "#increment_#{type}" do
            it "increments the ##{type}" do
                10.times do
                    subject.send( "increment_#{type}" )
                end

                expect(subject.send(type)).to eq 10
            end
        end
    end

    describe '#add_to_total_job_time' do
        it 'increments the #total_job_time' do
            subject.add_to_total_job_time( 1.0 )
            subject.add_to_total_job_time( 2.0 )

            expect(subject.total_job_time).to eq 3.0
        end
    end

    describe '#statistics' do
        let(:statistics) { subject.statistics }

        %w(pending_job_counter queued_job_count completed_job_count
            time_out_count total_job_time).each do |type|
            it "includes ##{type}" do
                subject.send("#{type}=", 1 )
                expect(subject.statistics[type.to_sym]).to eq 1
            end
        end
    end

    describe '#dump' do
        it 'stores #pending_jobs to disk' do
            subject.pending_jobs[1] = 2

            subject.dump( dump_directory )

            expect(Marshal.load(IO.read( "#{dump_directory}/pending_jobs" ))).to eq({ 1 => 2 })
        end

        it 'stores #job_callbacks to disk' do
            cb = proc_to_method {}
            subject.job_callbacks[1] = cb

            subject.dump( dump_directory )

            expect(Marshal.load(IO.read( "#{dump_directory}/job_callbacks" ))).to eq({ 1 => [ProcToMethod, :proc_to_method] })
        end

        %w(pending_job_counter job_id queued_job_count completed_job_count
            time_out_count total_job_time).each do |type|
            it "stores ##{type} to disk" do
                subject.send("#{type}=", 1 )

                subject.dump( dump_directory )

                expect(Marshal.load(IO.read( "#{dump_directory}/#{type}" ))).to eq 1
            end
        end
    end

    describe '.load' do
        it 'restores #pending_jobs from disk' do
            subject.pending_jobs[1] = 2

            subject.dump( dump_directory )

            pending_jobs = { 1 => 2 }
            expect(described_class.load( dump_directory).pending_jobs).to eq pending_jobs
        end

        it 'restores #job_callbacks from disk' do
            cb = proc_to_method {}
            subject.job_callbacks[1] = cb

            subject.dump( dump_directory )

            job_callbacks = { 1 => cb }
            expect(described_class.load( dump_directory).job_callbacks).to eq job_callbacks
        end

        %w(pending_job_counter job_id queued_job_count completed_job_count
            time_out_count total_job_time).each do |type|
            it "restores ##{type} to disk" do
                subject.send("#{type}=", 1 )

                subject.dump( dump_directory )

                expect(described_class.load( dump_directory).send(type)).to eq 1
            end
        end
    end

    describe '#clear' do
        %w(job_callbacks pending_jobs).each do |type|
            it "clears ##{type}" do
                subject.send(type)[1] = 2
                expect(subject.send(type)).not_to be_empty
                subject.clear
                expect(subject.send(type)).to be_empty
            end
        end

        %w(pending_job_counter job_id queued_job_count completed_job_count
            time_out_count total_job_time).each do |type|
            it "clears ##{type}" do
                subject.send("#{type}=", 1 )
                expect(subject.send(type)).to eq 1
                subject.clear
                expect(subject.send(type)).to eq 0
            end
        end
    end
end
