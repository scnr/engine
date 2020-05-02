=begin
    Copyright 2020 Alex Douckas <alexdouckas@gmail.com>, Tasos Laskos <tasos.laskos@gmail.com>

    This file is part of the SCNR::Engine project and is subject to
    redistribution and commercial restrictions. Please see the SCNR::Engine
    web site for more information on licensing and terms of use.
=end

# Extracts paths from `data-url` attributes.
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
class SCNR::Engine::Parser::Extractors::DataURL < SCNR::Engine::Parser::Extractors::Base

    def run
        return [] if !html || !check_for?( 'data-url' )

        html.scan( /data-url\s*=\s*['"]?(.*?)?['"]?[\s>]/ )
    end

end
