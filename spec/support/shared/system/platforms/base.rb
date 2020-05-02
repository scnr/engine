shared_examples_for 'SCNR::Engine::System::Platforms::Base' do
    subject { described_class.new }

    describe '#disk_directory' do
        it "delegates to #{SCNR::Engine::OptionGroups::Paths}#os_tmpdir" do
            expect(subject.disk_directory).to be SCNR::Engine::Options.paths.os_tmpdir
        end
    end

    describe '#disk_space_for_process' do
        it 'returns bytes of disk space used by the process' do
            expect(SCNR::Engine::Support::Database::Base).to receive(:disk_space_for).with(123).and_return(1000)

            expect(subject.disk_space_for_process( 123 )).to eq 1000
        end
    end

    describe '#cpu_count' do
        it 'returns the amount of CPUs' do
            expect(Concurrent).to receive(:processor_count).and_return(99)
            expect(subject.cpu_count).to eq 99
        end
    end

end
