=begin
    Copyright 2020 Alex Douckas <alexdouckas@gmail.com>, Tasos Laskos <tasos.laskos@gmail.com>

    This file is part of the SCNR::Engine project and is subject to
    redistribution and commercial restrictions. Please see the SCNR::Engine
    web site for more information on licensing and terms of use.
=end

class SCNR::Engine::Reporters::XML

# @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
class PluginFormatters::VectorCollector < SCNR::Engine::Plugin::Formatter

    def run( xml )
        results.each do |url, vectors|
            vectors.each do |vector|
                xml.vector {
                    xml.class_ vector['class']
                    xml.type vector['type']
                    xml.url SCNR::Engine::Reporters::XML.replace_nulls( vector['url'] )
                    xml.action SCNR::Engine::Reporters::XML.replace_nulls( vector['action'] )

                    if vector['source']
                        xml.source SCNR::Engine::Reporters::XML.replace_nulls( vector['source'] )
                    end

                    if vector['method']
                        xml.method_ vector['method']
                    end

                    if vector['inputs']
                        xml.inputs {
                            vector['inputs'].each do |k, v|
                                xml.input(
                                    name:  SCNR::Engine::Reporters::XML.replace_nulls( k ),
                                    value: SCNR::Engine::Reporters::XML.replace_nulls( v )
                                )
                            end
                        }
                    end
                }
            end
        end
    end

end
end
