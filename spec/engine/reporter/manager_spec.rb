require 'spec_helper'

describe SCNR::Engine::Reporter::Manager do
    before( :each ) do
        SCNR::Engine::Options.paths.reporters = fixtures_path + 'reporters/manager_spec/'
    end

    after { subject.clear }
    subject { described_class.new }
    let(:report) { Factory[:report] }

    describe '#run' do
        it 'runs a reporter by name' do
            subject.run( 'foo', report )

            expect(File.exist?( "#{SCNR::Engine::Options.paths.tmpdir}/foo" )).to be_truthy
        end

        context 'when options are given' do
            it 'passes them to the reporter' do
                options = { 'outfile' => 'stuff' }
                reporter = subject.run( :foo, report, options )

                expect(reporter.options).to eq(options.my_symbolize_keys(false))
            end
        end

        context 'when the raise argument is'do
            context 'not given' do
                context 'and the report raises an exception' do
                    it 'does not raise it' do
                        expect { subject.run( :error, report ) }.to_not raise_error
                    end
                end
            end

            context 'false' do
                context 'and the report raises an exception' do
                    it 'does not raise it' do
                        expect { subject.run( :error, report, {}, false ) }.to_not raise_error
                    end
                end
            end

            context 'true' do
                context 'and the report raises an exception' do
                    it 'does not raise it' do
                        expect { subject.run( :error, report, {}, true ) }.to raise_error
                    end
                end
            end
        end
    end

    describe '#reset' do
        it "delegates to #{described_class}.reset" do
            allow(described_class).to receive(:reset) { :stuff }
            expect(subject.reset).to eq(:stuff)
        end
    end

end
