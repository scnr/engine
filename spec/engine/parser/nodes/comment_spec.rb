require 'spec_helper'

describe SCNR::Engine::Parser::Nodes::Comment do
    subject { SCNR::Engine::Parser.parse_fragment( html ) }
    let(:html) { "<!-- #{value} -->" }
    let(:value) { 'my comment' }

    describe '#text' do
        it 'returns the given value' do
            expect(subject.text).to eq value
        end
    end

    describe '#to_html' do
        it 'returns the given value' do
            expect(subject.to_html).to eq "<!-- my comment -->\n"
        end
    end
end
