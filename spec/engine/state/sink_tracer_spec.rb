require 'spec_helper'

describe SCNR::Engine::State::SinkTracer do

    subject { described_class.new }
    let(:dump_directory) do
        "#{Dir.tmpdir}/sink-tracer-#{SCNR::Engine::Utilities.generate_token}"
    end
    let(:element) {  Factory[:form] }

    describe '#sinks' do
        it "returns an instance of #{SCNR::Engine::Support::Hash}" do
            expect(subject.sinks).to be_kind_of SCNR::Engine::Support::Hash
        end
    end

    describe '#dump' do
        it 'stores #sinks to disk' do
            element.affected_input_name = element.inputs.keys.first
            subject.push( element, :traced )

            subject.dump( dump_directory )

            d = SCNR::Engine::Support::Hash.new( :long_to_ruby )
            d[element.coverage_hash] = { traced: Set.new( [element.inputs.keys.first] ) }

            expect(Marshal.load( IO.read( "#{dump_directory}/sinks" ) )).to eq(d)
        end
    end

    describe '.load' do
        it 'loads #seen_responses_filter from disk' do
            element.affected_input_name = element.inputs.keys.first
            subject.push( element, :traced )

            subject.dump( dump_directory )

            d = SCNR::Engine::Support::Hash.new( :long_to_ruby )
            d[element.coverage_hash] = { traced: Set.new( [element.inputs.keys.first] ) }

            expect(described_class.load( dump_directory ).sinks).to eq(d)
        end
    end

    describe '#clear' do
        %w(sinks).each do |method|
            it "clears ##{method}" do
                expect(subject.send(method)).to receive(:clear)
                subject.clear
            end
        end
    end
end
