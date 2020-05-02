require 'spec_helper'

describe SCNR::Engine::Support::Hash do
    subject { described_class.new( type, data ) }
    let(:type) { :int_to_int }
    let(:data) { {} }

    it 'supports Marshal' do
        h = { 1 => 2, 3 => 4, 5 => 6, 7 => 8 }
        subject.merge!( h )

        expect(Marshal.load( Marshal.dump( subject ) ) ).to eq subject
    end

    describe '#initialize' do
        context 'when given data' do
            let(:data) { { 1 => 2 } }

            it 'uses them to populates the hash' do
                expect(subject).to eq described_class.new( type ).merge( data )
            end
        end

        describe ':int_to_int' do
            let(:type) { :int_to_int }

            if SCNR::Engine.windows?
                it "uses #{Hash}" do
                    expect(subject.klass).to eq Hash
                end
            else
                it "uses #{GoogleHashDenseIntToInt}" do
                    expect(subject.klass).to eq GoogleHashDenseIntToInt
                end
            end
        end

        describe ':int_to_long' do
            let(:type) { :int_to_long }

            if SCNR::Engine.windows?
                it "uses #{Hash}" do
                    expect(subject.klass).to eq Hash
                end
            else
                it "uses #{GoogleHashDenseIntToLong}" do
                    expect(subject.klass).to eq GoogleHashDenseIntToLong
                end
            end
        end

        describe ':int_to_ruby' do
            let(:type) { :int_to_ruby }

            if SCNR::Engine.windows?
                it "uses #{Hash}" do
                    expect(subject.klass).to eq Hash
                end
            else
                it "uses #{GoogleHashDenseIntToRuby}" do
                    expect(subject.klass).to eq GoogleHashDenseIntToRuby
                end
            end
        end

        describe ':long_to_int' do
            let(:type) { :long_to_int }

            if SCNR::Engine.windows?
                it "uses #{Hash}" do
                    expect(subject.klass).to eq Hash
                end
            else
                it "uses #{GoogleHashDenseLongToInt}" do
                    expect(subject.klass).to eq GoogleHashDenseLongToInt
                end
            end
        end

        describe ':long_to_long' do
            let(:type) { :long_to_long }

            if SCNR::Engine.windows?
                it "uses #{Hash}" do
                    expect(subject.klass).to eq Hash
                end
            else
                it "uses #{GoogleHashDenseLongToLong}" do
                    expect(subject.klass).to eq GoogleHashDenseLongToLong
                end
            end
        end

        describe ':long_to_ruby' do
            let(:type) { :long_to_ruby }

            if SCNR::Engine.windows?
                it "uses #{Hash}" do
                    expect(subject.klass).to eq Hash
                end
            else
                it "uses #{GoogleHashDenseLongToRuby}" do
                    expect(subject.klass).to eq GoogleHashDenseLongToRuby
                end
            end
        end

        describe ':ruby_to_ruby' do
            let(:type) { :ruby_to_ruby }

            if SCNR::Engine.windows?
                it "uses #{Hash}" do
                    expect(subject.klass).to eq Hash
                end
            else
                it "uses #{GoogleHashDenseRubyToRuby}" do
                    expect(subject.klass).to eq GoogleHashDenseRubyToRuby
                end
            end
        end

        describe ':ruby' do
            let(:type) { :ruby }

            it "uses #{Hash}" do
                expect(subject.klass).to eq Hash
            end
        end

        describe 'other' do
            let(:type) { :stuff }

            it "raises #{ArgumentError}" do
                expect do
                    subject
                end.to raise_error ArgumentError
            end
        end
    end

    describe '#first' do
        it 'returns the first name and value'
    end

    describe '#[]' do
        context 'when the key exists' do
            before do
                subject[1] = 2
            end

            it 'returns the associated value' do
                expect(subject[1]).to be 2
            end
        end

        context 'when the key does not exist' do
            it 'returns nil' do
                expect(subject[1]).to be_nil
            end
        end
    end

    describe '#[]=' do
        it 'assigns the value to the key' do
            subject[1] = 2
            expect(subject[1]).to be 2
        end
    end

    describe '#delete' do
        context 'when the key exists' do
            before do
                subject[1] = 2
            end

            it 'removes it' do
                subject.delete( 1 )
                expect(subject).to_not include 1
            end

            it 'returns its value' do
                expect(subject.delete( 1 )).to be 2
            end
        end

        context 'when the key does not exist' do
            it 'returns nil' do
                expect(subject.delete( 1 )).to be_nil
            end
        end
    end

    describe '#include?' do
        context 'when the key exists' do
            before do
                subject[1] = 2
            end

            it 'returns true' do
                expect(subject).to include 1
            end
        end

        context 'when the key does not exist' do
            it 'returns false' do
                expect(subject).to_not include 1
            end
        end
    end

    describe '#each' do
        before do
            subject[1] = 2
            subject[3] = 4
        end

        it 'iterates over all key-value pairs' do
            h = {}
            subject.each do |k, v|
                h[k] = v
            end

            expect(h).to eq({ 1 => 2, 3 => 4 })
        end
    end

    describe '#keys' do
        before do
            subject[1] = 2
            subject[3] = 4
        end

        it 'returns all keys' do
            expect(subject.keys).to eq([1,3])
        end
    end

    describe '#values' do
        before do
            subject[1] = 2
            subject[3] = 4
        end

        it 'returns all values' do
            expect(subject.values).to eq([2,4])
        end
    end

    describe '#merge' do
        before do
            subject[1] = 2
            subject[3] = 4
        end

        it "returns a new #{described_class}" do
            expect(subject.merge({ 5 => 6, 7 => 8 }).object_id).to_not eq subject.object_id
        end

        context "when given a #{Hash}" do
            it 'merges their data' do
                m = subject.merge({ 5 => 6, 7 => 8 })
                h = {}

                m.each do |k, v|
                    h[k] = v
                end

                expect(h).to eq({ 1 => 2, 3 => 4, 5 => 6, 7 => 8 })
            end
        end

        context "when given a #{Hash}" do
            it 'merges their data' do
                other = described_class.new( type )
                other[5] = 6
                other[7] = 8

                m = subject.merge( other )
                h = {}

                m.each do |k, v|
                    h[k] = v
                end

                expect(h).to eq({ 1 => 2, 3 => 4, 5 => 6, 7 => 8 })
            end
        end

        context 'when given something else' do
            it "raises #{ArgumentError}" do
                expect do
                    subject.merge( 1 )
                end.to raise_error ArgumentError
            end
        end
    end

    describe '#merge!' do
        before do
            subject[1] = 2
            subject[3] = 4
        end

        it 'returns self' do
            expect(subject.merge!({ 5 => 6, 7 => 8 }).object_id).to eq subject.object_id
        end

        context "when given a #{Hash}" do
            it 'merges their data' do
                subject.merge!({ 5 => 6, 7 => 8 })

                h = {}
                subject.each do |k, v|
                    h[k] = v
                end

                expect(h).to eq({ 1 => 2, 3 => 4, 5 => 6, 7 => 8 })
            end
        end

        context "when given a #{Hash}" do
            it 'merges their data' do
                other = described_class.new( type )
                other[5] = 6
                other[7] = 8

                subject.merge!( other )

                h = {}
                subject.each do |k, v|
                    h[k] = v
                end

                expect(h).to eq({ 1 => 2, 3 => 4, 5 => 6, 7 => 8 })
            end
        end

        context 'when given something else' do
            it "raises #{ArgumentError}" do
                expect do
                    subject.merge!( 1 )
                end.to raise_error ArgumentError
            end
        end
    end

    describe '#size' do
        it 'returns the hash size' do
            h = { 1 => 2, 3 => 4, 5 => 6, 7 => 8 }
            expect(subject.merge!( h ).size).to eq 4
        end
    end

    describe '#empty?' do
        context 'when the hash is empty' do
            it 'returns true' do
                expect(subject).to be_empty
            end
        end

        context 'when the hash is not empty' do
            it 'returns true' do
                subject[1] = 2
                expect(subject).to_not be_empty
            end
        end
    end

    describe '#any?' do
        context 'when the hash is empty' do
            it 'returns false' do
                expect(subject).to_not be_any
            end
        end

        context 'when the hash is not empty' do
            it 'returns true' do
                subject[1] = 2
                expect(subject).to be_any
            end
        end
    end

    describe '#clear' do
        it 'empties the hash' do
            subject[1] = 2
            subject.clear
            expect(subject).to be_empty
        end

        it 'returns self' do
            subject[1] = 2
            expect(subject.clear).to be subject
        end
    end

    describe '#to_h' do
        it "returns a #{Hash} with the same data" do
            h = { 1 => 2, 3 => 4, 5 => 6, 7 => 8 }
            expect(subject.merge!( h ).to_h).to eq h
        end
    end

    describe '#dup' do
        it 'returns a copy' do
            h = { 1 => 2, 3 => 4, 5 => 6, 7 => 8 }
            subject.merge!( h )

            expect(subject.dup).to eq subject
            expect(subject.dup).to_not be subject
        end
    end

    describe '#hash' do
        context 'when 2 hashes are identical' do
            it 'returns the same value' do
                h = { 1 => 2, 3 => 4, 5 => 6, 7 => 8 }

                subject.merge!( h )
                other = described_class.new( type ).merge( h )

                expect(subject.hash).to eq other.hash
            end
        end

        context 'when 2 hashes are different' do
            it 'returns different values' do
                h = { 1 => 2, 3 => 4, 5 => 6, 7 => 8 }

                subject.merge!( h )
                other = described_class.new( type ).merge( h )
                other[9] = 10

                expect(subject.hash).to_not eq other.hash
            end
        end
    end

    describe '#==' do
        context 'when 2 hashes are identical' do
            it 'returns true' do
                h = { 1 => 2, 3 => 4, 5 => 6, 7 => 8 }

                subject.merge!( h )
                other = described_class.new( type ).merge( h )

                expect(subject).to eq other
            end
        end

        context 'when 2 hashes are different' do
            it 'returns false' do
                h = { 1 => 2, 3 => 4, 5 => 6, 7 => 8 }

                subject.merge!( h )
                other = described_class.new( type ).merge( h )
                other[9] = 10

                expect(subject).to_not eq other
            end
        end
    end
end
