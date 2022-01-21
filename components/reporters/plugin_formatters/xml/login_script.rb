=begin
    Copyright 2020-2022 Tasos Laskos <tasos.laskos@gmail.com>

    This file is part of the SCNR::Engine project and is subject to
    redistribution and commercial restrictions. Please see the SCNR::Engine
    web site for more information on licensing and terms of use.
=end

class SCNR::Engine::Reporters::XML

# @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
class PluginFormatters::LoginScript < SCNR::Engine::Plugin::Formatter

    def run( xml )
        xml.message results['message']
        xml.status results['status']

        if results['cookies']
            xml.cookies {
                results['cookies'].each { |name, value| xml.cookie name: name, value: value }
            }
        end
    end

end
end
