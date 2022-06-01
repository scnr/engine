require 'spec_helper'

describe SCNR::Engine::Support::Database::Queue do

    subject { described_class.new }
    let(:sample_size) { 200 }

    it 'maintains stability and consistency under load' do
        subject

        entries = 1000
        poped   = Queue.new
        t       = []

        10.times do
            t << Thread.new do
                loop do
                    poped << subject.pop
                end
            end
        end

        entries.times do |i|
            subject << 'a' * i
        end

        sleep 0.1 while !subject.empty?

        consumed = []
        consumed << poped.pop while !poped.empty?

        expect(consumed.sort).to eq((0...entries).map { |i| 'a' * i })
    end

    describe '#initialize' do
        describe ':dumper' do
            it 'defaults to Marshal'

            context 'it responds to :dump' do
                it 'gets called to serialize the object' do
                    class Dumper; def self.dump(o) "#{o}-" end ;end

                    d = described_class.new(
                        dumper: Dumper
                    )
                    d << 1

                    pending
                end
            end

            context 'it responds to :call' do
                it 'gets called to serialize the object' do
                    d = described_class.new(
                        dumper: proc do |o|
                            o.to_s   << '-'
                        end
                    )
                    d << 1

                    pending
                end
            end
        end

        describe ':load' do
            context 'it responds to :load' do
                it 'gets called to unserialize the object' do
                    class Loader; def self.load(source) source + '-' end; end

                    d = described_class.new(
                        loader: Loader
                    )
                    d << 1

                    expect(d.pop).to eq Marshal.dump( 1 ) + '-'
                end
            end

            context 'it responds to :call' do
                it 'gets called to unserialize the object' do
                    d = described_class.new(
                        loader: proc do |o, io|
                            o + '-'
                        end
                    )
                    d << 1

                    expect(d.pop).to eq Marshal.dump( 1 ) + '-'
                end
            end
        end
    end

    describe '#empty?' do
        context 'when the queue is empty' do
            it 'returns true' do
                expect(subject.empty?).to be_truthy
            end
        end

        context 'when the queue is not empty' do
            it 'returns false' do
                subject << :stuff
                expect(subject.empty?).to be_falsey
            end
        end
    end

    describe '#<<' do
        it 'pushes an object' do
            subject << "stuff 1"
            expect(subject.pop).to eq("stuff 1")
        end
    end

    describe '#push' do
        it 'pushes an object' do
            subject.push :stuff
            expect(subject.pop).to eq(:stuff)
        end
    end

    describe '#enq' do
        it 'pushes an object' do
            subject.enq :stuff
            expect(subject.pop).to eq(:stuff)
        end
    end

    describe '#pop' do
        it 'removes an object' do
            subject << "stuff 1"
            expect(subject.pop).to eq("stuff 1")
        end

        it 'blocks until an entry is available' do
            val = nil

            t = Thread.new { val = subject.pop }
            sleep 1
            Thread.new { subject << :stuff }
            t.join

            expect(val).to eq(:stuff)
        end
    end

    describe '#deq' do
        it 'removes an object' do
            subject << :stuff
            expect(subject.deq).to eq(:stuff)
        end
    end

    describe '#shift' do
        it 'removes an object' do
            subject << :stuff
            expect(subject.shift).to eq(:stuff)
        end
    end

    describe '#size' do
        it 'returns the size of the queue' do
            sample_size.times { |i| subject << i }
            expect(subject.size).to eq(sample_size)
        end
    end

    describe '#num_waiting' do
        it 'returns the amount of threads waiting to pop' do
            expect(subject.num_waiting).to eq(0)

            2.times do
                Thread.new { subject.pop }
            end
            sleep 0.1

            expect(subject.num_waiting).to eq(2)
        end
    end

    describe '#clear' do
        it 'empties the queue' do
            sample_size.times { |i| subject << i }
            subject.clear
            expect(subject.size).to eq(0)
        end
    end

end
