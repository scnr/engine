require 'spec_helper'

describe SCNR::Engine::Data::Plugins do
    subject { described_class.new }
    let(:framework) { SCNR::Engine::Framework.new }
    let(:plugins) { framework.plugins }
    let(:dump_directory) do
        "#{Dir.tmpdir}/plugins-#{SCNR::Engine::Utilities.generate_token}"
    end

    describe '#statistics' do
        it 'includes plugin names' do
            plugins.load :distributable
            result = { 'stuff' => 1 }

            subject.store( plugins.create(:distributable), result )

            expect(subject.statistics[:names]).to eq([:distributable])
        end
    end

    describe '#results' do
        it 'returns a Hash' do
            expect(subject.results).to be_kind_of Hash
        end
    end

    describe '#store' do
        it 'stores plugin results' do
            plugins.load :distributable
            result = { stuff: 1 }

            subject.store( plugins.create(:distributable), result )
            expect(subject.results[:distributable][:results]).to eq(result)
        end
    end

    describe '#dump' do
        it 'stores #results to disk' do
            subject.store( plugins.create(:distributable), stuff: 1 )
            subject.dump( dump_directory )

            results_file = "#{dump_directory}/results/distributable"
            expect(File.exists?( results_file )).to be_truthy
            expect(subject.results).to eq({
                distributable: Marshal.load( IO.read( results_file ) )
            })
        end
    end

    describe '.load' do
        it 'loads #results from disk' do
            subject.store( plugins.create(:distributable), stuff: 1 )
            subject.dump( dump_directory )

            expect(subject.results).to eq(described_class.load( dump_directory ).results)
        end
    end

    describe '#clear' do
        %w(results).each do |method|
            it "clears ##{method}" do
                expect(subject.send(method)).to receive(:clear)
                subject.clear
            end
        end
    end
end
