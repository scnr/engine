=begin
    Copyright 2020 Alex Douckas <alexdouckas@gmail.com>, Tasos Laskos <tasos.laskos@gmail.com>

    This file is part of the SCNR::Engine project and is subject to
    redistribution and commercial restrictions. Please see the SCNR::Engine
    web site for more information on licensing and terms of use.
=end

module SCNR::Engine
module Platform::Fingerprinters

# Identifies CherryPy resources.
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
# @version 0.1
class CherryPy < Platform::Fingerprinter

    def run
        return if !server_or_powered_by_include?( 'cherrypy' )

        update_platforms
    end

    def update_platforms
        platforms << :python << :cherrypy
    end

end

end
end
