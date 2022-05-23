shared_examples_for 'plugin' do
    include_examples 'component'

    before( :each ) do
        options.paths.plugins = nil

        framework.plugins.lib = options.paths.plugins
        framework.plugins.load @name
    end

    let(:plugin) { framework.plugins[component_name] }
    let(:actual_results) { results_for( component_name ) }

    def results
    end

    def self.easy_test( match = true, &block )
        it 'logs the expected results' do
            raise 'No results provided via #results, use \':nil\' for \'nil\' results.' if !results

            run
            expect(actual_results).to eq( expected_results ) if match

            instance_eval &block if block_given?
        end
    end

    def run
        framework.run

        # Make sure plugin formatters work as well.
        # framework.reporters.load_all
        # framework.reporters.each do |name, _|
        #     framework.reporters[name].new( framework.report, outfile: outfile ).run
        #     File.delete( outfile ) rescue nil
        # end
    end

    def plugin
        framework.plugins[component_name]
    end

    def actual_results
        results_for( component_name )
    end

    def results_for( name )
        (framework.plugins.results[component_name.to_sym] || {})[:results]
    end

    def expected_results
        return nil if results == :nil

        (results.is_a?( String ) && results.include?( '__URL__' )) ?
            yaml_load( results ) : results
    end

end
