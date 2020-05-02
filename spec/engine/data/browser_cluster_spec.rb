require 'spec_helper'

describe SCNR::Engine::Data::BrowserCluster do

    subject do
        s = described_class.new
        s.job_queue.prefer = proc {}
        s
    end
    let(:job) { Factory[:custom_job] }
    let(:dump_directory) do
        "#{Dir.tmpdir}/browser-cluster-#{SCNR::Engine::Utilities.generate_token}"
    end

    describe '#statistics' do
        let(:statistics) { subject.statistics }

        it 'includes the #job_queue size' do
            subject.job_queue << job
            subject.job_queue << job

            expect(statistics[:job_queue_size]).to eq 2
        end
    end

    describe '#dump' do
        it 'stores #job_queue to disk' do
            cj = job.dup.tap { |j| j.category = :crawl }
            aj = job.dup.tap { |j| j.category = :audit }
            j  = job.dup.tap { |j| j.category = nil }

            subject.job_queue << cj
            subject.job_queue << aj
            subject.job_queue << j

            subject.dump( dump_directory )

            job_queue = described_class.load( dump_directory ).job_queue
            job_queue.prefer = proc{}

            expect(job_queue.data_for(:crawl)[:buffer]).to be_empty
            expect(job_queue.data_for(:crawl)[:disk].size).to eq 1
            expect(job_queue.unserialize(IO.read(job_queue.data_for(:crawl)[:disk].first))).to eq cj

            expect(job_queue.data_for(:audit)[:buffer]).to be_empty
            expect(job_queue.data_for(:audit)[:disk].size).to eq 1
            expect(job_queue.unserialize(IO.read(job_queue.data_for(:audit)[:disk].first))).to eq aj

            expect(job_queue.data_for(nil)[:buffer]).to be_empty
            expect(job_queue.data_for(nil)[:disk].size).to eq 1
            expect(job_queue.unserialize(IO.read(job_queue.data_for(nil)[:disk].first))).to eq j

            expect(job_queue.disk_size).to eq 3

            jobs = []
            3.times do
                jobs << job_queue.pop
            end

            expect(jobs).to eq [cj, aj, j]
        end

    end
end
