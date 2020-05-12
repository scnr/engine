require 'spec_helper'

describe SCNR::Engine::State::Framework::RPC do
    subject { described_class.new }
    let(:dump_directory) do
        "#{Dir.tmpdir}/rpc-#{SCNR::Engine::Utilities.generate_token}"
    end
    let(:page) { Factory[:page] }
    let(:url) { page.url }

    describe '#distributed_pages' do
        it "returns an instance of #{SCNR::Engine::Support::Filter::Set}" do
            expect(subject.distributed_pages).to be_kind_of SCNR::Engine::Support::Filter::Set
        end
    end

    describe '#distributed_elements' do
        it "returns an instance of #{Set}" do
            expect(subject.distributed_elements).to be_kind_of Set
        end
    end

    describe '#statistics' do
        let(:statistics) { subject.statistics }

        it 'includes the size of #distributed_pages' do
            subject.distributed_pages << url
            expect(statistics[:distributed_pages]).to eq(subject.distributed_pages.size)
        end

        it 'includes the size of #distributed_elements' do
            subject.distributed_elements << url.persistent_hash
            expect(statistics[:distributed_elements]).to eq(subject.distributed_elements.size)
        end
    end

    describe '#dump' do
        it 'stores #distributed_pages to disk' do
            subject.distributed_pages << url
            subject.dump( dump_directory )

            d = SCNR::Engine::Support::Filter::Set.new(hasher: :persistent_hash )
            d << url

            expect(Marshal.load( IO.read( "#{dump_directory}/distributed_pages" ) )).to eq(d)
        end

        it 'stores #distributed_elements to disk' do
            subject.distributed_elements << url.persistent_hash
            subject.dump( dump_directory )

            expect(Marshal.load( IO.read( "#{dump_directory}/distributed_elements" ) )).to eq(Set.new([url.persistent_hash]))
        end
    end

    describe '.load' do
        it 'loads #distributed_pages from disk' do
            subject.distributed_pages << url
            subject.dump( dump_directory )

            d = SCNR::Engine::Support::Filter::Set.new(hasher: :persistent_hash )
            d << url

            expect(described_class.load( dump_directory ).distributed_pages).to eq(d)
        end

        it 'loads #distributed_elements from disk' do
            subject.distributed_elements << url.persistent_hash
            subject.dump( dump_directory )

            expect(described_class.load( dump_directory ).distributed_elements).
                to eq(Set.new([url.persistent_hash]))
        end
    end

    describe '#clear' do
        %w(distributed_pages distributed_elements).each do |method|
            it "clears ##{method}" do
                expect(subject.send(method)).to receive(:clear)
                subject.clear
            end
        end
    end
end
