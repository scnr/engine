require 'spec_helper'

describe SCNR::Engine::Browser::Engines::None do

    describe '#initialize' do
        it 'fails' do
            expect { subject }.to raise_error
        end
    end

    describe '.name' do
        it 'returns :none' do
            expect(described_class.name).to be :none
        end
    end

end
