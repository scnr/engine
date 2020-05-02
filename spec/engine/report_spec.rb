require 'spec_helper'

describe SCNR::Engine::Report do

    before( :each ) do
        SCNR::Engine::Options.url = url
    end

    after :each do
        File.delete( @report_file ) rescue nil
    end

    let(:url) { 'http://test.com/' }
    let( :report_data ) { Factory[:report_data] }
    let( :report ) { Factory[:report] }
    let( :report_empty ) { Factory[:report_empty] }
    let( :passive_issue ) { Factory[:passive_issue] }
    let( :active_issue ) { Factory[:active_issue] }

    it "supports #{SCNR::Engine::RPC::Serializer}" do
        report.options.delete :input

        cloned = SCNR::Engine::RPC::Serializer.deep_clone( report )
        cloned.options.delete :input

        expect(report).to eq(cloned)
    end

    describe '#to_rpc_data' do
        let(:subject) { report }
        let(:data) { subject.to_rpc_data }

        %w(seed sitemap version).each do |attribute|
            it "includes '#{attribute}'" do
                expect(data[attribute]).to eq(subject.send( attribute ))
            end
        end

        it "includes 'options'" do
            expect(data['options']).to eq(
                SCNR::Engine::Options.update( subject.options ).to_rpc_data
            )
        end

        it "includes 'plugins'" do
            options_1 = data['plugins'].map { |name, d| d[:options] }
            options_2 = subject.plugins.map { |name, d| d[:options].map(&:to_rpc_data) }

            info_1 = data['plugins'].each { |name, d| d.delete :options }
            info_2 = subject.plugins.each { |name, d| d.delete :options }

            expect(info_1).to eq(info_2)
            expect(options_1).to eq(options_2)
        end

        it "includes 'issues'" do
            expect(data['issues']).to eq(subject.issues.map(&:to_rpc_data))
        end

        %w(start_datetime finish_datetime).each do |attribute|
            it "includes '#{attribute}'" do
                expect(data[attribute]).to eq(subject.send( attribute ).to_s)
            end
        end
    end

    describe '.from_rpc_data' do
        let(:subject) { report }

        let(:restored) { described_class.from_rpc_data data }
        let(:data) { SCNR::Engine::RPC::Serializer.rpc_data( subject ) }

        %w(seed sitemap issues plugins version).each do |attribute|
            it "restores '#{attribute}'" do
                expect(restored.send( attribute )).to eq(subject.send( attribute ))
            end
        end

        it "restores 'options'" do
            restored.options.delete :input
            subject.options.delete :input

            expect(restored.options).to eq(subject.options)
        end

        %w(start_datetime finish_datetime).each do |attribute|
            it "restores '#{attribute}'" do
                expect(restored.send( attribute )).to be_kind_of Time
                expect(restored.send( attribute ).to_s).to eq(subject.send( attribute ).to_s)
            end
        end
    end

    describe '#version' do
        it 'returns the version number' do
            expect(report.version).to eq(SCNR::Engine::VERSION)
        end
    end

    describe '#seed' do
        it 'returns the scan seed' do
            expect(report.seed).to eq(SCNR::Engine::Utilities.random_seed)
        end
    end

    describe '#url' do
        it 'returns the targeted URL' do
            expect(report.url).to eq(report.options[:url])
        end
    end

    describe '#options' do
        it 'returns scan options' do
            new  = described_class.new.options
            updated = SCNR::Engine::Options.dup.update( new ).to_hash
            hash    = SCNR::Engine::Options.to_hash

            new.delete :input
            hash.delete :input
            updated.delete :input

            expect(hash).to eq(updated)
        end
    end

    describe '#sitemap' do
        it 'returns the sitemap' do
            expect(report.sitemap).to eq({url => 200})
        end
    end

    describe '#issues' do
        it 'returns the issues' do
            issues = [Factory[:issue]]
            expect(described_class.new( issues: issues ).issues).to eq(issues)
        end
    end

    describe '#issue_by_check' do
        it 'returns issue logged by the given check' do
            expect(report.issues).to be_any

            report.issues.first.check[:shortname] << 'stuff'

            check = report.issues.first.check[:shortname]

            filtered_issues = report.issues_by_check( check )
            filtered_issues.each do |issue|
                expect(issue.check[:shortname]).to eq(check)
            end

            expect(report.issues.size).to be > filtered_issues.size
        end
    end

    describe '#issue_by_digest' do
        it 'returns an issue based on its digest' do
            expect(report.issues).to be_any

            report.issues.each do |issue|
                expect(report.issue_by_digest( issue.digest )).to eq(issue)
            end
        end
    end

    describe '#plugins' do
        it 'returns the plugin results' do
            expect(report.plugins).to eq(Factory[:report_data][:plugins])
        end
    end

    describe '#start_datetime' do
        it 'returns a Time object' do
            expect(report.start_datetime).to be_kind_of Time
        end
        context 'when no start datetime info has been provided' do
            it 'falls-back to Time.now' do
                expect(report_empty.start_datetime).to be_kind_of Time
            end
        end
    end

    describe '#finish_datetime' do
        it 'returns a Time object' do
            expect(report.finish_datetime).to be_kind_of Time
        end
        it 'returns the start finish of the scan' do
            expect(report.finish_datetime.to_s).to eq(
                Factory[:report_data][:finish_datetime].to_s
            )
        end
        context 'when no start datetime info has been provided' do
            it 'falls-back to Time.now' do
                expect(report_empty.finish_datetime).to be_kind_of Time
            end
        end
    end

    describe '#delta_time' do
        it 'returns the time difference between start and finish time' do
            expect(report.delta_time).to eq('02:46:40')
        end
        context 'when no #finish_datetime has been provided' do
            it 'uses Time.now for the calculation' do
                report_empty.start_datetime = Time.now - 2000
                expect(report_empty.delta_time.to_s).to eq('00:33:19')
            end
        end
    end

    describe '.read_summary' do
        it 'returns summary' do
            @report_file = report.save
            expect(described_class.read_summary( @report_file )).to eq(
                SCNR::Engine::RPC::Serializer.load( SCNR::Engine::RPC::Serializer.dump( report.summary ) )
            )
        end
    end

    describe '#save' do
        it 'dumps the object to a file' do
            @report_file = report.save

            expect(described_class.load( @report_file )).to eq(report)
        end

        context 'when given a location' do
            context 'which is a filepath' do
                it 'saves the object to that file' do
                    @report_file = 'report'
                    report.save( @report_file )

                    expect(described_class.load( @report_file )).to eq(report)
                end
            end

            context 'which is a directory' do
                it 'saves the object under that directory' do
                    directory = Dir.tmpdir
                    @report_file = report.save( directory )

                    expect(described_class.load( @report_file )).to eq(report)
                end
            end
        end
    end

    describe '#to_ser' do
        it 'returns the object in AFR format' do
            @report_file = report.save

            expect(IO.binread( @report_file )).to eq(report.to_ser)
        end
    end

    describe '#to_h' do
        it 'returns the object as a hash' do
            expect(report.to_h).to eq({
                version:         report.version,
                status:          report.status,
                seed:            report.seed,
                options:         SCNR::Engine::Options.hash_to_rpc_data( report.options ),
                sitemap:         report.sitemap,
                start_datetime:  report.start_datetime.to_s,
                finish_datetime: report.finish_datetime.to_s,
                delta_time:      report.delta_time,
                issues:          report.issues.map(&:to_h),
                plugins:         {
                    plugin_name: {
                        results: 'stuff',
                        options: [
                            {
                                name:        :some_name,
                                required:    false,
                                value:       nil,
                                description: 'Some description.',
                                default:     'default_value',
                                choices:      %w(available values go here),
                                type:        :multiple_choice
                            }
                        ]
                    }
                }
            })
        end
    end

    describe '#to_hash' do
        it 'alias of #to_h' do
            expect(report.to_h).to eq(report.to_hash)
        end
    end

    describe '#==' do
        context 'when the reports are equal' do
            it 'returns true' do
                expect(report.deep_clone).to eq(report)
            end
        end
        context 'when the reports are not equal' do
            it 'returns false' do
                a = report.deep_clone
                a.options[:url] = 'http://stuff/'
                expect(a).not_to eq(report)
            end
        end
    end

end
