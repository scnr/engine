require 'spec_helper'

describe SCNR::Engine::Browser::Engines::Chrome do
    include_examples 'browser_engine'

    describe '.name' do
        it 'returns :chrome' do
            expect(described_class.name).to be :chrome
        end
    end

    describe '#name' do
        it 'returns :chrome' do
            expect(subject.name).to be :chrome
        end
    end

    describe '#console' do
        it 'returns the browser console contents'
    end

end

