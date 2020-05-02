=begin
    Copyright 2020 Alex Douckas <alexdouckas@gmail.com>, Tasos Laskos <tasos.laskos@gmail.com> 

    This file is part of the SCNR::Engine project and is subject to
    redistribution and commercial restrictions. Please see the SCNR::Engine
    web site for more information on licensing and terms of use.
=end

class SCNR::Engine::Reporters::XML

# XML formatter for the results of the ContentTypes plugin
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
class PluginFormatters::ContentTypes < SCNR::Engine::Plugin::Formatter

    def run( xml )
        results.each do |type, infos|
            infos.each do |info|
                xml.entry {
                    xml.content_type type
                    xml.url  info['url']
                    xml.method_ info['method']

                    xml.parameters {
                        info['parameters'].each do |name, value|
                            xml.parameter(
                                name: SCNR::Engine::Reporters::XML.replace_nulls( name ),
                                value: SCNR::Engine::Reporters::XML.replace_nulls( value )
                            )
                        end
                    }

                }
            end
        end
    end

end
end
