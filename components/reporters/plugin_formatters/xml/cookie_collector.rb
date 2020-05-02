=begin
    Copyright 2020 Tasos Laskos <tasos.laskos@gmail.com>

    This file is part of the SCNR::Engine project and is subject to
    redistribution and commercial restrictions. Please see the SCNR::Engine
    web site for more information on licensing and terms of use.
=end

class SCNR::Engine::Reporters::XML

# XML formatter for the results of the CookieCollector plugin
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
class PluginFormatters::CookieCollector < SCNR::Engine::Plugin::Formatter

    def run( xml )
        results.each_with_index do |result, i|
            xml.entry {
                xml.time Time.parse( result['time'] ).xmlschema
                xml.url XML.replace_nulls( result['response']['url'] )

                xml.cookies {
                    result['cookies'].each do |name, value|
                        xml.cookie(
                            name:  SCNR::Engine::Reporters::XML.replace_nulls( name ),
                            value: SCNR::Engine::Reporters::XML.replace_nulls( value )
                        )
                    end
                }
            }
        end
    end

end
end
