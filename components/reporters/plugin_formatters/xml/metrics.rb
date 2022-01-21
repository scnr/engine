=begin
    Copyright 2020-2022 Tasos Laskos <tasos.laskos@gmail.com>

    This file is part of the SCNR::Engine project and is subject to
    redistribution and commercial restrictions. Please see the SCNR::Engine
    web site for more information on licensing and terms of use.
=end

class SCNR::Engine::Reporters::XML

# @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
class PluginFormatters::Metrics < SCNR::Engine::Plugin::Formatter

    def run( xml )
        results.each do |category, data|
            xml.send( category ) {
                data.each do |k, v|
                    if category == 'platforms'
                        v = v.join( ',' )
                    end

                    xml.send k, v
                end
            }
        end
    end

end
end
