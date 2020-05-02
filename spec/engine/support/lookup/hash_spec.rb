require 'spec_helper'

describe SCNR::Engine::Support::LookUp::Hash do
    it_behaves_like 'lookup'

    describe '#merge' do
        it 'merges 2 sets' do
            new = described_class.new

            subject << 'test'
            new     << 'test2'

            subject.merge new
            expect(subject).to include 'test'
            expect(subject).to include 'test2'
        end
    end

    describe '#replace' do
        it 'replaces the contents of the set with another' do
            new = described_class.new

            subject << 'test'
            new     << 'test2'

            subject.replace new

            expect(subject).to include 'test2'
            expect(subject.include?( 'test' )).to be_falsey
        end
    end
end
