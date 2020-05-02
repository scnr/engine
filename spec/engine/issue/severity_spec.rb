require 'spec_helper'

describe SCNR::Engine::Issue::Severity do
    describe 'Engine::Issue::Severity::HIGH' do
        it 'returns "high"' do
            expect(SCNR::Engine::Issue::Severity::HIGH.to_s).to eq('high')
        end
    end
    describe 'Engine::Issue::Severity::MEDIUM' do
        it 'returns "medium"' do
            expect(SCNR::Engine::Issue::Severity::MEDIUM.to_s).to eq('medium')
        end
    end
    describe 'Engine::Issue::Severity::LOW' do
        it 'returns "low"' do
            expect(SCNR::Engine::Issue::Severity::LOW.to_s).to eq('low')
        end
    end
    describe 'Engine::Issue::Severity::INFORMATIONAL' do
        it 'returns "informational"' do
            expect(SCNR::Engine::Issue::Severity::INFORMATIONAL.to_s).to eq('informational')
        end
    end

    it 'is assigned to Engine::Severity for easy access' do
        expect(SCNR::Engine::Severity).to eq(SCNR::Engine::Issue::Severity)
    end

    it 'is comparable' do
        informational = SCNR::Engine::Issue::Severity::INFORMATIONAL
        low           = SCNR::Engine::Issue::Severity::LOW
        medium        = SCNR::Engine::Issue::Severity::MEDIUM
        high          = SCNR::Engine::Issue::Severity::HIGH

        expect(informational).to be < low
        expect(low).to be < medium
        expect(medium).to be < high

        expect([low, informational, high, medium].sort).to eq(
            [informational, low, medium, high]
        )
    end

end
