shared_examples_for 'with_sinks' do |options = {}|
    it_should_behave_like 'sinks', options

    describe '#sinks' do
        it "returns the element's sinks" do
            expect(subject.sinks).to be_kind_of described_class::Sinks
        end
    end

    describe '#coverage_and_trace_id' do
        it 'takes into account the #coverage_id' do
            allow(subject).to receive(:coverage_id) { '1' }

            subject2 = subject.dup
            allow(subject2).to receive(:coverage_id) { '2' }

            expect(subject.coverage_and_trace_id).not_to eq subject2.coverage_and_trace_id

            allow(subject2).to receive(:coverage_id) { '1' }

            expect(subject.coverage_and_trace_id).to eq subject2.coverage_and_trace_id
        end

        it 'takes into account whether or not the sinks have been traced' do
            allow(subject.sinks).to receive(:traced?) { true }

            subject2 = subject.dup
            allow(subject2.sinks).to receive(:traced?) { false }

            expect(subject.coverage_and_trace_id).not_to eq subject2.coverage_and_trace_id

            allow(subject2.sinks).to receive(:traced?) { true }

            expect(subject.coverage_and_trace_id).to eq subject2.coverage_and_trace_id
        end
    end

    describe '#coverage_and_trace_hash' do
        it 'takes into account the #coverage_id' do
            allow(subject).to receive(:coverage_id) { '1' }

            subject2 = subject.dup
            allow(subject2).to receive(:coverage_id) { '2' }

            expect(subject.coverage_and_trace_hash).not_to eq subject2.coverage_and_trace_hash

            allow(subject2).to receive(:coverage_id) { '1' }

            expect(subject.coverage_and_trace_hash).to eq subject2.coverage_and_trace_hash
        end

        it 'takes into account whether or not the sinks have been traced' do
            allow(subject.sinks).to receive(:traced?) { true }

            subject2 = subject.dup
            allow(subject2.sinks).to receive(:traced?) { false }

            expect(subject.coverage_and_trace_hash).not_to eq subject2.coverage_and_trace_hash

            allow(subject2.sinks).to receive(:traced?) { true }

            expect(subject.coverage_and_trace_hash).to eq subject2.coverage_and_trace_hash
        end
    end

    describe '#to_rpc_data' do
        it 'does not include sinks' do
            expect(subject.to_rpc_data).not_to include 'sinks'
        end
    end
end
