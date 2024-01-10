class SCNR::Engine::Reporters::Stdout

# @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
class PluginFormatters::SinkTracer < SCNR::Engine::Plugin::Formatter

    def run
        print_info "Seed: #{results.first['mutation']['seed']}"
        print_line
        print_info 'Reflected sinks'
        print_info ' -- The seed was found present in the HTTP response or the DOM.'
        print_line
        results.each do |result|
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
        results.each do |result|
            next if !sinks_for( result ).include?( 'active' )

            print_result( result )

            if result['page'] && result['page']['dom'] && (dfs = result['page']['dom']['data_flow_sinks']).any?
                print_line " -- Data flow:"
                dfs.each.with_index do |df, idx|
                    print_line "[#{idx+1}] -- #{df['object']}.#{df['function']['name']}( #{df['function']['arguments'].join( ', ' )} )"
                    print_line "[#{idx+1}] ---- Trace"
                    df['trace'].each do |t|
                        next if t['url'].include? 'javascript.browser.scnr.engine'
                        print_line "[#{idx+1}] ------ #{t['function']['name']}() at #{t['url']} line #{t['line']}"
                    end
                    print_line "[#{idx+1}] ---- Source:"
                    print_line df['function']['source']
                    print_line
                end
            end

            print_line
        end

        print_line
        print_info 'Blind sinks'
        print_info ' -- Could not discern functionality being activated in the web application.'
        print_line
        results.each do |result|
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
          "#{result['mutation']['type']} via " <<
          "#{result['mutation']['method'].upcase} #{result['mutation']['action']}"
        print_line " -- Using: #{result['mutation']['inputs'][result['mutation']['affected_input_name']].inspect}"
        print_line " -- Inputs:"
        result['mutation']['inputs'].each do |k, v|
            print_line " ---- #{k.inspect} = #{v.inspect}"
        end
    end
end

end
