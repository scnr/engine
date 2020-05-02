=begin
    Copyright 2020 Tasos Laskos <tasos.laskos@gmail.com>

    This file is part of the SCNR::Engine project and is subject to
    redistribution and commercial restrictions. Please see the SCNR::Engine
    web site for more information on licensing and terms of use.
=end

class SCNR::Engine::Reporters::XML

# @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
class PluginFormatters::Exec < SCNR::Engine::Plugin::Formatter

    def run( xml )
        results.each do |stage, data|
            xml.outcome {
                xml.stage stage
                data.each do |name, value|
                    xml.send( name, value )
                end
            }
        end
    end

end
end
