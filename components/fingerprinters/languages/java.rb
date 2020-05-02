=begin
    Copyright 2020 Tasos Laskos <tasos.laskos@gmail.com>

    This file is part of the SCNR::Engine project and is subject to
    redistribution and commercial restrictions. Please see the SCNR::Engine
    web site for more information on licensing and terms of use.
=end

module SCNR::Engine
module Platform::Fingerprinters

# Identifies Java resources.
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
# @version 0.1.3
class Java < Platform::Fingerprinter

    EXTENSION = 'jsp'
    SESSIONID = 'jsessionid'

    def run
        if extension == EXTENSION || parameters.include?( SESSIONID ) ||
            server_or_powered_by_include?( 'java' ) ||
            server_or_powered_by_include?( 'servlet' ) ||
            server_or_powered_by_include?( 'jsp' ) ||
            server_or_powered_by_include?( 'jboss' ) ||
            server_or_powered_by_include?( 'glassfish' ) ||
            server_or_powered_by_include?( 'oracle' ) ||
            cookies.include?( SESSIONID )

            platforms << :java
        end
    end

end

end
end
