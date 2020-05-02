require 'spec_helper'

describe SCNR::Engine::Browser::Engines do

    describe '.supported' do
        it 'returns all available engines' do
            expect(described_class.supported).to eq({
                none:    SCNR::Engine::Browser::Engines::None,
                firefox: SCNR::Engine::Browser::Engines::Firefox,
                chrome:  SCNR::Engine::Browser::Engines::Chrome
            })
        end
    end

end
