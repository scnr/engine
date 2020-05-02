shared_examples_for 'reporter' do
    include_examples 'component'

    before( :each ) { framework.reporters.load name }
    after( :each ) { File.delete( outfile ) rescue nil }

    let(:reporters) { framework.reporters }
    let(:outfile) { "#{Dir.tmpdir}/#{(0..10).map{ rand( 9 ).to_s }.join}" }
    let(:full_report) { SCNR::Engine::Report.load( fixtures_path + "/report.#{SCNR::Engine::Report::EXTENSION}" ) }
    let(:empty_report) { SCNR::Engine::Report.new( options: { url: 'http://test.com' } ) }

    def self.test_with_full_report( &block )
        it 'formats a full report' do
            run( full_report )
            instance_eval( &block ) if block_given?
        end
    end

    def self.test_with_empty_report( &block )
        it 'can handle an empty report' do
            run( empty_report )
            instance_eval( &block ) if block_given?
        end
    end

    def run( report )
        reporters[name].new( report, outfile: outfile ).run
    end

end
