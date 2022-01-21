=begin
    Copyright 2020-2022 Tasos Laskos <tasos.laskos@gmail.com>

    This file is part of the SCNR::Engine project and is subject to
    redistribution and commercial restrictions. Please see the SCNR::Engine
    web site for more information on licensing and terms of use.
=end

class SCNR::Engine::Reporters::XML

# XML formatter for the results of the HealthMap plugin
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
class PluginFormatters::HealthMap < SCNR::Engine::Plugin::Formatter

    def run( xml )
        xml.map {
            results['map'].each do |i|
                xml.send( i.keys[0], i.values[0] )
            end
        }

        xml.total results['total']
        xml.with_issues results['with_issues']
        xml.without_issues results['without_issues']
        xml.issue_percentage results['issue_percentage']
    end

end
end
