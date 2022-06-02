require 'spec_helper'

shared_examples_for 'filter' do
    subject { described_class.new }

    it { is_expected.to respond_to :collection }

    describe '#<<' do
        it 'adds an object and return self' do
            expect(subject << 'test').to eq(subject)
        end
    end

    describe '#include?' do
        context 'when an object is included' do
            it 'returns true' do
                subject << 'test'
                subject << 'test2'

                expect(subject.include?( 'test' )).to be_truthy
                expect(subject.include?( 'test2' )).to be_truthy
            end
        end
        context 'when an object is not included' do
            it 'returns false' do
                expect(subject.include?( 'test3' )).to be_falsey
            end
        end
    end

    describe '#empty?' do
        context 'when empty' do
            it 'returns true' do
                expect(subject.empty?).to be_truthy
            end
        end
        context 'when not empty' do
            it 'returns false' do
                subject << 'test'
                expect(subject.empty?).to be_falsey
            end
        end
    end

    describe '#any?' do
        context 'when empty' do
            it 'returns false' do
                expect(subject.any?).to be_falsey
            end
        end
        context 'when not empty' do
            it 'returns true' do
                subject << 'test'
                expect(subject.any?).to be_truthy
            end
        end
    end

    describe '#clear' do
        it 'empties the list' do
            bf = described_class.new
            bf << '1'
            bf << '2'
            bf.clear
            expect(bf.include?( '1' )).to be_falsey
            expect(bf.include?( '2' )).to be_falsey
        end
    end

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

    describe '#dup' do
        it 'returns a copy' do
            subject << 'test'
            copy = subject.dup

            copy << 'test2'

            expect(copy.include?('test')).to be_truthy
            expect(copy.include?('test2')).to be_truthy
            expect(subject.include?('test2')).to be_falsey
        end
    end

end
