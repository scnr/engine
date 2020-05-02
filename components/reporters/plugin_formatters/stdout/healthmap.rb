=begin
    Copyright 2020 Tasos Laskos <tasos.laskos@gmail.com>

    This file is part of the SCNR::Engine project and is subject to
    redistribution and commercial restrictions. Please see the SCNR::Engine
    web site for more information on licensing and terms of use.
=end

class SCNR::Engine::Reporters::Stdout

# Stdout formatter for the results of the HealthMap plugin
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
class PluginFormatters::HealthMap < SCNR::Engine::Plugin::Formatter

    def run
        print_info 'Legend:'
        print_ok 'No issues'
        print_bad 'Has issues'
        print_line

        results['map'].sort_by { |_, v| v }.each do |i|
            state = i.keys[0]
            url   = i.values[0]

            if state == 'with_issues'
                print_bad( url )
            else
                print_ok( url )
            end
        end

        print_line

        print_info "Total: #{results['total']}"
        print_ok "Without issues: #{results['without_issues']}"
        print_bad "With issues: #{results['with_issues']} ( #{results['issue_percentage'].to_s}% )"
    end

end
end
