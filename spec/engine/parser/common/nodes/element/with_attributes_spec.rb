require 'spec_helper'

describe SCNR::Engine::Parser::Common::Nodes::Element::WithAttributes do
    subject { SCNR::Engine::Parser.parse_fragment( html ) }
    let(:html) {
        <<-EOHTML
            <div id="my-id" ClaSS="my-class"></div>
        EOHTML
    }

    describe '#attributes' do
        it "returns #{described_class::Attributes}" do
            expect(subject.attributes).to be_kind_of described_class::Attributes
        end

        it 'includes the native attributes' do
            expect(subject.attributes).to eq({
                'id'    => 'my-id',
                'class' => 'my-class'
            })
        end
    end

    describe '#[]' do
        it 'converts the key to string' do
            expect(subject['id']).to eq 'my-id'
        end
    end

end
