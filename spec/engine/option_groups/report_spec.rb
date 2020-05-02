require 'spec_helper'

describe SCNR::Engine::OptionGroups::Report do
    include_examples 'option_group'
    subject { described_class.new }

    %w(path).each do |method|
        it { is_expected.to respond_to method }
        it { is_expected.to respond_to "#{method}=" }
    end

    describe '#path' do
        context "when #{SCNR::Engine::OptionGroups::Paths}.config['reports']" do
            it 'returns it' do
                allow(SCNR::Engine::OptionGroups::Paths).to receive(:config) do
                    {
                        'reports' => Dir.tmpdir
                    }
                end

                expect(subject.path).to eq(Dir.tmpdir + '/')
            end
        end
    end

end
