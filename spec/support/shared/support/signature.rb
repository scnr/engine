require 'spec_helper'

shared_examples_for 'signature' do

    def string_with_noise
        <<-END
                This #{rand(999999)} is a #{"\0"} test.
                Not #{rand(999999)} really sure what #{rand(999999)} else to put here...
                #{rand(999999)}
        END
    end

    def different_string_with_noise
        <<-END
                This #{rand(999999)} is a different #{"\0"} test.
        END
    end

    let(:signature) { described_class.new( string_with_noise ) }

    describe '.for_or_refine' do
        context 'when a signature is given' do
            it 'refines it'
        end

        context 'when no signature is given' do
            it 'returns a new one'
        end
    end

    describe '.for' do
        it 'returns a signature from the given data'
    end

    describe '.refine' do
        it 'returns a refined signature'
    end

    describe '.similar?' do
        context 'when the signatures are similar' do
            it 'returns true'
        end

        context 'when the signatures are not similar' do
            it 'returns false'
        end
    end

    describe '#refine' do
        context 'when given a String' do
            it 'removes noise from the signature' do
                expect(string_with_noise).not_to eq(string_with_noise)

                signature1 = described_class.new( string_with_noise )

                10.times{ signature1 = signature1.refine( string_with_noise ) }

                signature2 = described_class.new( string_with_noise )
                10.times{ signature2 = signature2.refine( string_with_noise ) }

                expect(signature1).to eq(signature2)
            end

            it 'returns a new signature instance' do
                signature1 = described_class.new( string_with_noise )
                expect(signature1.refine( string_with_noise ).object_id).not_to eq(signature1.object_id)
            end
        end

        context "when given a #{described_class}" do
            it 'removes noise from the signature' do
                expect(string_with_noise).not_to eq(string_with_noise)

                signature1 = described_class.new( string_with_noise )

                10.times{ signature1 = signature1.refine( described_class.new( string_with_noise ) ) }

                signature2 = described_class.new( string_with_noise )
                10.times{ signature2 = signature2.refine( described_class.new( string_with_noise ) ) }

                expect(signature1).to eq(signature2)
            end

            it 'returns a new signature instance' do
                signature1 = described_class.new( string_with_noise )
                expect(signature1.refine( described_class.new( string_with_noise ) ).object_id).not_to eq(signature1.object_id)
            end
        end
    end

    describe '#refine!' do
        context 'when given a String' do
            it 'destructively removes noise from the signature' do
                expect(string_with_noise).not_to eq(string_with_noise)

                signature1 = described_class.new( string_with_noise )
                10.times{ signature1.refine!( string_with_noise ) }

                signature2 = described_class.new( string_with_noise )
                10.times{ signature2.refine!( string_with_noise ) }

                expect(signature1).to eq(signature2)
            end

            it 'returns self' do
                signature = described_class.new( string_with_noise )
                expect(signature.refine!( string_with_noise ).object_id).to eq(signature.object_id)
            end

            it 'resets #hash' do
                signature = described_class.new( string_with_noise )

                ph = signature.hash

                signature.refine!( string_with_noise )
                h = signature.hash

                expect(ph).not_to eq h
            end
        end

        context "when given a #{described_class}" do
            it 'destructively removes noise from the signature' do
                expect(string_with_noise).not_to eq(string_with_noise)

                signature1 = described_class.new( string_with_noise )
                10.times{ signature1.refine!( described_class.new( string_with_noise ) ) }

                signature2 = described_class.new( string_with_noise )
                10.times{ signature2.refine!( described_class.new( string_with_noise ) ) }

                expect(signature1).to eq(signature2)
            end

            it 'returns self' do
                signature = described_class.new( string_with_noise )
                expect(signature.refine!( described_class.new( string_with_noise ) ).object_id).to eq(signature.object_id)
            end

            it 'resets #hash' do
                signature = described_class.new( string_with_noise )

                ph = signature.hash

                signature.refine!( described_class.new( string_with_noise ) )
                h = signature.hash

                expect(ph).not_to eq h
            end
        end
    end

    describe '#similar?' do
        let(:signature_1) { described_class.new( '1 2 3' ) }
        let(:signature_2) { described_class.new( '1 2 4' ) }

        context 'when identical' do
            it 'returns true' do
                s1 = described_class.new( '1 2 3' )
                s2 = described_class.new( '1 2 3' )

                expect(signature_1.similar?( signature_2, 0.51 )).to be true
            end

            context 'and empty' do
                it 'returns true' do
                    s1 = described_class.new( '' )
                    s2 = described_class.new( '' )

                    expect(signature_1.similar?( signature_2, 0.51 )).to be true
                end
            end
        end

        context 'when the difference ratio is bellow the threshold' do
            it 'returns true' do
                s1 = described_class.new( '1 2 3' )
                s2 = described_class.new( '1 2 4' )

                expect(signature_1.similar?( signature_2, 0.51 )).to be true
            end
        end

        context 'when the difference ratio is above the threshold' do
            it 'returns false' do
                s1 = described_class.new( '1 2 3' )
                s2 = described_class.new( '1 2 4' )

                expect(signature_1.similar?( signature_2, 0.49 )).to be false
            end
        end
    end

    describe '#<<' do
        it 'pushes new data to the signature' do
            string = string_with_noise
            d1 = string.lines[0..-3].join
            d2 = string.lines[-2..-1].join

            signature = described_class.new( d1 )
            t1 = signature.tokens

            signature << d2

            t2 = signature.tokens

            expect(Set.new( t1 )).to be_subset Set.new( t2 )
        end

        it 'returns self' do
            signature = described_class.new( string_with_noise )
            expect((signature << string_with_noise ).object_id).to eq(signature.object_id)
        end

        it 'resets #hash' do
            signature = described_class.new( string_with_noise )

            ph = signature.hash

            signature << string_with_noise
            h = signature.hash

            expect(ph).not_to eq h
        end
    end

    describe '#differences' do
        it 'returns ratio of differences between signatures' do
            signature1 = described_class.new( string_with_noise )
            signature2 = described_class.new( string_with_noise )
            signature3 = described_class.new( different_string_with_noise )
            signature4 = described_class.new( different_string_with_noise )

            expect(signature1.differences( signature2 ).round(3)).to eq(0.4)
            expect(signature2.differences( signature2 )).to eq(0)

            expect(signature3.differences( signature4 ).round(3)).to eq(0.286)
            expect(signature4.differences( signature4 )).to eq(0)
            expect(signature1.differences( signature3 ).round(3)).to eq(0.778)
        end
    end

    describe '#empty?' do
        context 'when the signature is empty' do
            subject { described_class.new( '' ) }

            expect_it { to be_empty }
        end

        context 'when the signature is not empty' do
            subject { described_class.new( string_with_noise ) }

            expect_it { to_not be_empty }
        end
    end

    describe '#clear' do
        subject { described_class.new( string_with_noise ) }

        it 'empties the tokens' do
            expect(subject).to_not be_empty
            subject.clear
            expect(subject).to be_empty
        end
    end

    describe '#size' do
        subject { described_class.new( string_with_noise ) }

        it 'returns the amount of tokens' do
            expect(subject.tokens.size).to eq 16
            expect(subject.clear.size).to eq 0
        end
    end

    describe '#==' do
        context 'when the signature are identical' do
            it 'returns true' do
                signature1 = described_class.new( string_with_noise )
                10.times{ signature1.refine!( string_with_noise ) }

                signature2 = described_class.new( string_with_noise )
                10.times{ signature2.refine!( string_with_noise ) }

                expect(signature1).to eq(signature2)
            end
        end

        context 'when the signature are not identical' do
            it 'returns false' do
                signature1 = described_class.new( string_with_noise )
                10.times{ signature1.refine!( string_with_noise ) }

                signature2 = described_class.new( different_string_with_noise )
                10.times{ signature2.refine!( different_string_with_noise ) }

                expect(signature1).not_to eq(signature2)
            end
        end
    end

    describe '#dup' do
        it 'returns a duplicate instance' do
            expect(signature.dup).to eq(signature)
            expect(signature.dup.object_id).not_to eq(signature.object_id)
        end
    end
end
