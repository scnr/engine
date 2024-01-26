=begin
    Copyright 2024 Ecsypno Single Member P.C.

    This file is part of the SCNR::Engine project and is subject to
    redistribution and commercial restrictions. Please see the SCNR::Engine
    web site for more information on licensing and terms of use.
=end

module SCNR::Engine
module Platform::Fingerprinters

# Identifies Tomcat web servers.
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
# @version 0.1
class Tomcat < Platform::Fingerprinter

    IDS = %w(coyote tomcat)

    def run
        IDS.each do |id|
            next if !server_or_powered_by_include? id

            return update_platforms
        end
    end

    def update_platforms
        platforms << :java << :tomcat
    end

end

end
end
