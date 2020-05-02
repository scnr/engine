require 'spec_helper'

describe SCNR::Engine::Data::Framework::RPC do
    subject { described_class.new }
    let(:dump_directory) do
        "#{Dir.tmpdir}/rpc-#{SCNR::Engine::Utilities.generate_token}"
    end
    let(:page) { Factory[:page] }
    let(:url) { page.url }

    describe '#distributed_page_queue' do
        it "returns an instance of #{SCNR::Engine::Support::Database::Queue}" do
            expect(subject.distributed_page_queue).to be_kind_of SCNR::Engine::Support::Database::Queue
        end
    end

    describe '#statistics' do
        it 'includes #distributed_page_queue size' do
            subject.distributed_page_queue << page
            expect(subject.statistics[:distributed_page_queue]).to eq(
                subject.distributed_page_queue.size
            )
        end
    end

    describe '#dump' do
        it 'stores #distributed_page_queue to disk' do
            subject.distributed_page_queue.max_buffer_size = 1
            subject.distributed_page_queue << page
            subject.distributed_page_queue << page

            expect(subject.distributed_page_queue.buffer).to include page
            expect(subject.distributed_page_queue.disk.size).to eq(1)

            subject.dump( dump_directory )

            pages = []
            Dir["#{dump_directory}/distributed_page_queue/*"].each do |page_file|
                pages << subject.distributed_page_queue.unserialize( IO.binread( page_file ) )
            end
            expect(pages).to eq([page, page])
        end
    end

    describe '.load' do
        it 'loads #distributed_page_queue from disk' do
            subject.distributed_page_queue.max_buffer_size = 1
            subject.distributed_page_queue << page
            subject.distributed_page_queue << page

            subject.dump( dump_directory )

            page_queue = described_class.load( dump_directory ).distributed_page_queue
            expect(page_queue.size).to eq(2)
            expect(page_queue.pop).to eq(page)
            expect(page_queue.pop).to eq(page)
        end
    end

    describe '#clear' do
        %w(distributed_page_queue).each do |method|
            it "clears ##{method}" do
                expect(subject.send(method)).to receive(:clear)
                subject.clear
            end
        end
    end
end
