=begin
    Copyright 2020 Tasos Laskos <tasos.laskos@gmail.com>

    This file is part of the SCNR::Engine project and is subject to
    redistribution and commercial restrictions. Please see the SCNR::Engine
    web site for more information on licensing and terms of use.
=end

class SCNR::Engine::Reporters::Stdout

#
# @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
#
class PluginFormatters::UncommonHeaders < SCNR::Engine::Plugin::Formatter

    def run
        results.each do |url, headers|
            print_status url

            headers.each do |name, value|
                print_info "#{name}: #{value}"
            end

            print_line
        end
    end

end
end
