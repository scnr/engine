require 'spec_helper'

describe SCNR::Engine::Parser::Common::Nodes::Element::WithAttributes::Attributes do
    subject { described_class.new( 'KeY' => 'val' ) }

    describe '#[]' do
        it 'converts the key to string' do
            expect(subject['KeY']).to eq 'val'
        end
    end
end
