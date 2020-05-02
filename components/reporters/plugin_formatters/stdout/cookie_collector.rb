=begin
    Copyright 2020 Alex Douckas <alexdouckas@gmail.com>, Tasos Laskos <tasos.laskos@gmail.com>

    This file is part of the SCNR::Engine project and is subject to
    redistribution and commercial restrictions. Please see the SCNR::Engine
    web site for more information on licensing and terms of use.
=end

class SCNR::Engine::Reporters::Stdout

# Stdout formatter for the results of the CookieCollector plugin
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
class PluginFormatters::CookieCollector < SCNR::Engine::Plugin::Formatter

    def run
        results.each_with_index do |result, i|
            print_info "[#{(i + 1).to_s}] On #{result['time']}"
            print_info "URL: #{result['response']['url']}"

            print_info 'Cookies forced to: '
            result['cookies'].each_pair do |name, value|
                print_info "    #{name} => #{value}"
            end

            print_line
        end
    end

end
end
