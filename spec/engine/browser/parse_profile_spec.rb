require 'spec_helper'

describe SCNR::Engine::Browser::ParseProfile do

    subject { described_class.new }

    describe '#initialise' do
        described_class::ATTRIBUTES.each do |n|
            describe ":#{n}" do
                it "sets ##{n}" do
                    expect( described_class.new( n => false ).send( n ) ).to be false
                end

                describe 'by default' do
                    it 'is true' do
                        expect( subject.send( n ) ).to be true
                    end
                end
            end
        end
    end

    described_class::ATTRIBUTES.each do |n|
        describe "##{n}=" do
            it "sets ###{n}" do
                subject.send( "#{n}=", false )

                expect( subject.send( n ) ).to be false
            end
        end
    end

    describe '#only' do
        it 'enables the given attributes' do
            subject.only( :body, :elements )

            described_class::ATTRIBUTES.each do |n|
                next if n == :body || n == :elements
                expect( subject.send( n ) ).to be false
            end

            expect( subject.body ).to be true
            expect( subject.elements ).to be true
        end

        it 'returns self' do
            expect( subject.only( :body, :elements ) ).to be subject
        end
    end

    describe '#except' do
        it 'disables the given attributes' do
            subject.except( :body, :elements )

            described_class::ATTRIBUTES.each do |n|
                next if n == :body || n == :elements
                expect( subject.send( n ) ).to be true
            end

            expect( subject.body ).to be false
            expect( subject.elements ).to be false
        end

        it 'returns self' do
            expect( subject.except( :body, :elements ) ).to be subject
        end
    end

    describe '#disable!' do
        it 'disables all attributes' do
            subject.update( body: true, elements: true )
            subject.disable!

            expect( subject.body ).to be false
            expect( subject.elements ).to be false
        end

        it 'returns self' do
            expect( subject.disable! ).to be subject
        end
    end

    describe '#update' do
        it 'updates the given attributes' do
            subject.update( body: true, elements: false )

            expect( subject.body ).to be true
            expect( subject.elements ).to be false
        end

        it 'returns self' do
            expect( subject.update( body: true, elements: false ) ).to be subject
        end
    end

    describe '#disabled?' do
        context 'when all attributes are disabled' do
            it 'returns true' do
                subject.update described_class::ATTRIBUTES.inject({}) { |h, k| h.merge k => false }
                expect( subject ).to be_disabled
            end
        end

        context 'when some attributes are enabled' do
            it 'returns false' do
                subject.update described_class::ATTRIBUTES.inject({}) { |h, k| h.merge k => false }
                subject.update body: true
                expect( subject ).to_not be_disabled
            end
        end
    end

    describe '.only' do
        it 'enables the given attributes' do
            subject = described_class.only( :body, :elements )

            described_class::ATTRIBUTES.each do |n|
                next if n == :body || n == :elements
                expect( subject.send( n ) ).to be false
            end

            expect( subject.body ).to be true
            expect( subject.elements ).to be true
        end

        it 'returns an instance' do
            expect( described_class.only( :body, :elements ) ).to be_kind_of described_class
        end
    end

    describe '.except' do
        it 'disables the given attributes' do
            subject = described_class.except( :body, :elements )

            described_class::ATTRIBUTES.each do |n|
                next if n == :body || n == :elements
                expect( subject.send( n ) ).to be true
            end

            expect( subject.body ).to be false
            expect( subject.elements ).to be false
        end

        it 'returns an instance' do
            expect( described_class.except( :body, :elements ) ).to be_kind_of described_class
        end
    end

    describe '#disable!' do
        it 'disables all attributes' do
            subject = described_class.disable!

            described_class::ATTRIBUTES.each do |n|
                expect( subject.send( n ) ).to be false
            end
        end

        it 'returns an instance' do
            expect( described_class.disable! ).to be_kind_of described_class
        end
    end
end
