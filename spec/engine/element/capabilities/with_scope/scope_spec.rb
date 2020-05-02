require 'spec_helper'

describe SCNR::Engine::Element::Capabilities::WithScope::Scope do

    subject { SCNR::Engine::Element::Base.new( url: 'http://stuff/' ).scope }

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
    end
end
