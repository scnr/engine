require 'spec_helper'

describe SCNR::Engine::State::Trainer do

    subject { described_class.new }

    let(:dump_directory) do
        "#{Dir.tmpdir}/trainer-#{SCNR::Engine::Utilities.generate_token}"
    end
    let(:key) { 'some key here '}

    describe '#seen_responses_filter' do
        it "returns an instance of #{SCNR::Engine::Support::LookUp::Hash}" do
            expect(subject.seen_responses_filter).to be_kind_of SCNR::Engine::Support::LookUp::Hash
        end
    end

    describe '#seen_responses_filter?' do
        context 'when a page has already been seen' do
            it 'returns true' do
                subject.seen_responses_filter << key
                expect(subject.response_seen?( key )).to be_truthy
            end
        end

        context 'when a page has not been seen' do
            it 'returns false' do
                expect(subject.response_seen?( key )).to be_falsey
            end
        end
    end

    describe '#seen_responses_filter' do
        context 'when the given page has been marked as seen' do
            it 'returns true' do
                subject.response_seen key
                expect(subject.response_seen?( key )).to be_truthy
            end
        end

        context 'when the given page has not been marked as seen' do
            it 'returns false' do
                expect(subject.response_seen?( key )).to be_falsey
            end
        end
    end

    describe '#dump' do
        it 'stores #seen_responses_filter to disk' do
            subject.seen_responses_filter << key

            subject.dump( dump_directory )

            d = SCNR::Engine::Support::LookUp::Hash.new( hasher: :persistent_hash ).merge( [key] )
            expect(Marshal.load( IO.read( "#{dump_directory}/seen_responses_filter" ) )).to eq(d)
        end
    end

    describe '.load' do
        it 'loads #seen_responses_filter from disk' do
            subject.seen_responses_filter << key

            subject.dump( dump_directory )

            set = SCNR::Engine::Support::LookUp::Hash.new( hasher: :persistent_hash )
            set << key
            expect(described_class.load( dump_directory ).seen_responses_filter).to eq(set)
        end
    end

    describe '#clear' do
        %w(seen_responses_filter).each do |method|
            it "clears ##{method}" do
                expect(subject.send(method)).to receive(:clear)
                subject.clear
            end
        end
    end
end
