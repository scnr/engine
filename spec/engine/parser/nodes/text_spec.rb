require 'spec_helper'

describe SCNR::Engine::Parser::Nodes::Text do
    subject { SCNR::Engine::Parser::parse_fragment( html ) }
    let(:html) { value }
    let(:value) { 'my text' }

    describe '#text' do
        it 'returns the given value' do
            expect(subject.text).to eq value
        end
    end

    describe '#to_html' do
        it 'returns the given value' do
            expect(subject.to_html).to eq "my text\n"
        end
    end
end
