class SCNR::Engine::Reporters::Stdout

# @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
class PluginFormatters::SinkTracer < SCNR::Engine::Plugin::Formatter

    def run
        print_info "Seed: #{results.values.first['mutation']['seed']}"
        print_line
        print_info 'Reflected sinks'
        print_info ' -- The seed was found present in the HTTP response or the DOM.'
        print_line
        results.values.each do |result|
            sinks = sinks_for( result ) & %w(body header_name header_value)
            next if sinks.empty?

            print_result( result )
            print_line " -- Landed in: #{sinks.join( ', ')}"
            print_line
        end

        print_line
        print_info 'Active sinks'
        print_info ' -- Functionality was activated in the web application.'
        print_line
        results.values.each do |result|
            next if !sinks_for( result ).include?( 'active' )

            print_result( result )
            print_line
        end

        print_line
        print_info 'Blind sinks'
        print_info ' -- Could not discern functionality being activated in the web application.'
        print_line
        results.values.each do |result|
            next if !sinks_for( result ).include?( 'blind' )

            print_result( result )
            print_line
        end
    end

    def sinks_for( result )
        result['sinks'][result['mutation']['affected_input_name']]
    end

    def print_result( result )
        print_line "`#{result['mutation']['affected_input_name']}` " <<
          "#{result['mutation']['class'].split( '::' ).last.downcase} via " <<
          "#{result['mutation']['method'].upcase} #{result['mutation']['action']}"
        print_line " -- Using: #{result['mutation']['inputs'][result['mutation']['affected_input_name']]}"
    end
end

end
