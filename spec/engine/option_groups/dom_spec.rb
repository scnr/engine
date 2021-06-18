require 'spec_helper'

describe SCNR::Engine::OptionGroups::DOM do
    include_examples 'option_group'
    subject { described_class.new }

    %w(engine pool_size job_timeout worker_time_to_live
        wait_for_elements local_storage).each do |method|
        it { is_expected.to respond_to method }
        it { is_expected.to respond_to "#{method}=" }
    end

    describe '#engine=' do
        described_class::ENGINES.each do |engine|
            it "supports #{engine}" do
                subject.engine = engine
                expect(subject.engine).to eq engine
            end
        end

        it "defaults to #{described_class::DEFAULT_ENGINE}" do
            expect(subject.engine).to eq described_class::DEFAULT_ENGINE
        end

        context 'when :none is passed' do
            it 'zeroes out the #pool_size' do
                expect(subject.pool_size).to be > 0
                subject.engine = :none
                expect(subject.pool_size).to eq 0
            end
        end

        context 'when passed an unknown engine' do
            it "fails with #{ArgumentError}" do
                expect do
                    subject.engine = :stuff
                end.to raise_error ArgumentError
            end
        end
    end

    describe '#pool_size=' do
        context 'when given > 0' do
            it 'sets the #pool_size' do
                subject.pool_size = 1
                expect(subject.pool_size).to be 1
            end
        end

        context 'when given 0' do
            it 'sets the #pool_size' do
                subject.pool_size = 0
                expect(subject.pool_size).to be 0
            end
        end

        context 'when given < 0' do
            it "fails with #{ArgumentError}" do
                expect do
                    subject.pool_size = -1
                end.to raise_error ArgumentError
            end
        end
    end

    describe '#enabled?' do
        context 'when the #size is' do
            context '> 0' do
                before { subject.pool_size = 1 }
                it { is_expected.to be_enabled }
            end

            context '== 0' do
                before { subject.pool_size = 0 }
                it { is_expected.to_not be_enabled }
            end
        end
    end

    describe '#disabled?' do
        context 'when the #size is' do
            context '> 0' do
                before { subject.pool_size = 1 }
                it { is_expected.to_not be_disabled }
            end

            context '== 0' do
                before { subject.pool_size = 0 }
                it { is_expected.to be_disabled }
            end
        end
    end

    describe '#wait_for_elements' do
        it 'converts the keys to Regexp' do
            subject.wait_for_elements = {
                'article' => '.articles'
            }

            expect(subject.wait_for_elements).to eq({
                /article/i => '.articles'
            })
        end
    end

    describe '#to_rpc_data' do
        let(:data) { subject.to_rpc_data }

        it "converts 'wait_for_elements' to strings" do
            subject.wait_for_elements = {
                /stuff/ => '.my-element'
            }

            expect(data['wait_for_elements']).to eq({
                'stuff' => '.my-element'
            })
        end
    end

    describe '#local_storage' do
        context 'when passed a Hash' do
            it 'sets it' do
                subject.local_storage = { 1 => 2 }
                expect(subject.local_storage).to eq({ 1 => 2 })
            end
        end

        context 'when passed anything other than Hash' do
            it 'raises ArgumentError' do
                expect do
                    subject.local_storage = 1
                end.to raise_error ArgumentError
            end
        end
    end

    describe '#session_storage' do
        context 'when passed a Hash' do
            it 'sets it' do
                subject.session_storage = { 1 => 2 }
                expect(subject.session_storage).to eq({ 1 => 2 })
            end
        end

        context 'when passed anything other than Hash' do
            it 'raises ArgumentError' do
                expect do
                    subject.session_storage = 1
                end.to raise_error ArgumentError
            end
        end
    end
end
