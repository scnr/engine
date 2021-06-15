require 'spec_helper'

describe SCNR::Engine::Element::Capabilities::WithScope::Scope do

    after { described_class.reset }
    let(:element) { SCNR::Engine::Element::Base.new( url: 'http://stuff/' ) }
    subject { element.scope }

    describe '#out?' do
        it 'returns false' do
            expect(subject).not_to be_out
        end

        context 'when #redundant?' do
            context 'is true' do
                it 'returns true' do
                    allow(subject).to receive(:redundant?) { true }
                    expect(subject).to be_out
                end
            end
        end

        context "when #{SCNR::Engine::OptionGroups::Audit}#element?" do
            context 'is false' do
                it 'returns true' do
                    allow(SCNR::Engine::Options.audit).to receive(:element?) { false }
                    expect(subject).to be_out
                end
            end
        end

        context 'when .reject?' do
            context 'returns true' do
                it 'returns true' do
                    p = nil
                    described_class.reject do |element|
                        p = element
                        true
                    end

                    expect(subject.out?).to be_truthy
                    expect(p).to eq element
                end
            end
        end

        context 'when .select?' do
            context 'returns true' do
                it 'returns false' do
                    p = nil
                    described_class.select do |element|
                        p = element
                        true
                    end

                    expect(subject.out?).to be_falsey
                    expect(p).to eq element
                end
            end
        end
    end
end
