require 'spec_helper'

describe SCNR::Engine::Data::Session do
    subject { described_class.new }
    let(:framework) { SCNR::Engine::Framework.new }
    let(:plugins) { framework.plugins }
    let(:dump_directory) do
        "#{Dir.tmpdir}/session-#{SCNR::Engine::Utilities.generate_token}"
    end

    describe '#statistics' do
        it 'returns an empty Hash' do
            expect(subject.statistics).to eq({})
        end
    end

    describe '#configuration' do
        it 'returns an empty Hash' do
            expect(subject.configuration).to eq({})
        end
    end

    describe '#dump' do
        it 'stores #configuration to disk' do
            subject.configuration[:stuff] = [1]
            subject.dump( dump_directory )

            results_file = "#{dump_directory}/configuration"
            expect(File.exists?( results_file )).to be_truthy
            expect(subject.configuration).to eq({ stuff: [1] })
        end
    end

    describe '.load' do
        it 'loads #results from disk' do
            subject.configuration[:stuff] = [1]
            subject.dump( dump_directory )

            expect(subject.configuration).to eq(described_class.load( dump_directory ).configuration)
        end
    end

    describe '#clear' do
        %w(configuration).each do |method|
            it "clears ##{method}" do
                expect(subject.send(method)).to receive(:clear)
                subject.clear
            end
        end
    end
end
