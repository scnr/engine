require 'spec_helper'

describe SCNR::Engine::OptionGroups::Device do
    include_examples 'option_group'
    subject { described_class.new }

    %w(width height user_agent).each do |method|
        it { is_expected.to respond_to method }
        it { is_expected.to respond_to "#{method}=" }
    end

    describe '#user_agent' do
        it "defaults to 'Mozilla/5.0 (Gecko) SCNR::Engine/v#{SCNR::Engine::VERSION}'" do
            expect(subject.user_agent).to eq("Mozilla/5.0 (Gecko) SCNR::Engine/v#{SCNR::Engine::VERSION}")
        end
    end

end
