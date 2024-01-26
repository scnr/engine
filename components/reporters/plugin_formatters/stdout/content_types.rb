=begin
    Copyright 2024 Ecsypno Single Member P.C.

    This file is part of the SCNR::Engine project and is subject to
    redistribution and commercial restrictions. Please see the SCNR::Engine
    web site for more information on licensing and terms of use.
=end

class SCNR::Engine::Reporters::Stdout

# Stdout formatter for the results of the ContentTypes plugin
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
class PluginFormatters::ContentTypes < SCNR::Engine::Plugin::Formatter

    def run
        results.each do |type, responses|
            print_ok type

            responses.each do |res|
                print_status "    URL:    #{res['url']}"
                print_info   "    Method: #{res['method']}"

                if res['parameters'] && res['method'].downcase == 'post'
                    print_info '    Parameters:'
                    res['parameters'].each do |k, v|
                        print_info "        #{k} => #{v}"
                    end
                end

                print_line
            end

            print_line
        end
    end

end
end
