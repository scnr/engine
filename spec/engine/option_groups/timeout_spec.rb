require 'spec_helper'

describe SCNR::Engine::OptionGroups::Timeout do
    include_examples 'option_group'
    subject { described_class.new }

    %w(duration suspend).each do |method|
        it { is_expected.to respond_to method }
        it { is_expected.to respond_to "#{method}=" }
    end

end
