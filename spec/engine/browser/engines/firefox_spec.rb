require 'spec_helper'

describe SCNR::Engine::Browser::Engines::Firefox do
    include_examples 'browser_engine'

    describe '.name' do
        it 'returns :firefox' do
            expect(described_class.name).to be :firefox
        end
    end

    describe '#name' do
        it 'returns :firefox' do
            expect(subject.name).to be :firefox
        end
    end

    describe '#allow_request?' do
        let(:request) do
            SCNR::Engine::HTTP::Request.new( url: url )
        end

        context 'when the URL does not match any rules' do
            let(:url) { 'https://google.com/' }

            it 'returns true' do
                expect(subject.allow_request?( request )).to be_truthy
            end
        end

        context 'when the URL is for ciscobinary.openh264.org' do
            let(:url) { 'https://ciscobinary.openh264.org/stuff/' }

            it 'returns false' do
                expect(subject.allow_request?( request )).to be_falsey
            end
        end
    end

end

