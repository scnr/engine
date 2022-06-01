require 'spec_helper'

describe SCNR::Engine::Support::Database::CategorizedQueue do

    class Item
        attr_accessor :category
        attr_accessor :data

        def initialize( data )
            @data = data
        end

        def ==( other )
            data == other.data
        end

        def hash
            data.hash
        end
    end

    subject { described_class.new {} }

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
            subject << Item.new( 'a' * i )
        end

        sleep 0.1 while !subject.empty?

        consumed = []
        consumed << poped.pop.data while !poped.empty?

        expect(consumed.sort).to eq((0...entries).map { |i| 'a' * i })
    end

    describe '#initialize' do
        describe ':dumper' do
            it 'defaults to Marshal'

            context 'it responds to :dump' do
                it 'gets called to serialize the object'
            end

            context 'it responds to :call' do
                it 'gets called to serialize the object'
            end
        end

        describe ':load' do
            context 'it responds to :load' do
                it 'gets called to unserialize the object'
            end

            context 'it responds to :call' do
                it 'gets called to serialize the object'
            end
        end

        describe '&block' do
            it 'sets the #prefer block' do
                prefer = proc {}

                expect( described_class.new( &prefer ).prefer ).to be prefer
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
                subject << Item.new( :stuff )
                expect(subject.empty?).to be_falsey
            end
        end
    end

    describe '#<<' do
        it 'pushes an object' do
            sample_size.times do |i|
                subject << Item.new( "stuff #{i}" )
            end

            sample_size.times do |i|
                expect(subject.pop).to eq(Item.new( "stuff #{i}" ))
            end
        end

        context 'when no #prefer block has been set' do
            it "raises #{ArgumentError}" do
                expect {
                    described_class.new << Item.new( '' )
                }.to raise_error ArgumentError
            end
        end
    end

    describe '#push' do
        it 'pushes an object' do
            subject.push Item.new( :stuff )
            expect(subject.pop).to eq(Item.new( :stuff ))
        end
    end

    describe '#enq' do
        it 'pushes an object' do
            subject.enq Item.new( :stuff )
            expect(subject.pop).to eq(Item.new( :stuff ))
        end
    end

    describe '#pop' do
        it 'removes an object' do
            sample_size.times do |i|
                subject << Item.new( "stuff #{i}" )
            end

            sample_size.times do |i|
                expect(subject.pop).to eq(Item.new( "stuff #{i}" ))
            end
        end

        it 'blocks until an entry is available' do
            val = nil

            t = Thread.new { val = subject.pop }
            sleep 1
            Thread.new { subject << Item.new( :stuff ) }
            t.join

            expect(val).to eq(Item.new( :stuff ))
        end

        it 'gives preference to the category provided by the block' do
            subject = described_class.new { :stuff2 }

            subject << Item.new( 1 ).tap { |s| s.category = :stuff }
            subject << Item.new( 2 ).tap { |s| s.category = :stuff2 }
            subject << Item.new( 3 ).tap { |s| s.category = :stuff3 }

            expect(subject.pop.data).to eq 2
            expect(subject.pop.data).to eq 3
            expect(subject.pop.data).to eq 1
        end

        context 'when the block specified category is empty' do
            it 'returns an item from the next one' do
                subject = described_class.new { :stuff4 }

                subject << Item.new( 1 ).tap { |s| s.category = :stuff }
                subject << Item.new( 2 ).tap { |s| s.category = :stuff2 }
                subject << Item.new( 3 ).tap { |s| s.category = :stuff3 }

                expect(subject.pop.data).to eq 3
                expect(subject.pop.data).to eq 2
                expect(subject.pop.data).to eq 1
            end
        end

        context 'when no #prefer block has been set' do
            it "raises #{ArgumentError}" do
                expect {
                    described_class.new.pop
                }.to raise_error ArgumentError
            end
        end
    end

    describe '#deq' do
        it 'removes an object' do
            subject << Item.new( :stuff )
            expect(subject.deq).to eq(Item.new( :stuff ))
        end
    end

    describe '#shift' do
        it 'removes an object' do
            subject << Item.new( :stuff )
            expect(subject.shift).to eq(Item.new( :stuff ))
        end
    end

    describe '#size' do
        it 'returns the size of the queue' do
            sample_size.times { |i| subject << Item.new( i ) }
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
            sample_size.times { |i| subject << Item.new( i ) }
            subject.clear
            expect(subject.size).to eq(0)
            expect((subject.pop( true ) rescue nil)).to eq(nil)
        end
    end

end
