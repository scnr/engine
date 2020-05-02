require 'spec_helper'

describe SCNR::Engine::Scope do

    subject { described_class.new }

    describe '#options' do
        it "returns #{SCNR::Engine::OptionGroups::Scope}" do
            expect(subject.options).to be_kind_of SCNR::Engine::OptionGroups::Scope
        end
    end

end
