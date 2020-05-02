=begin
    Copyright 2020 Alex Douckas <alexdouckas@gmail.com>, Tasos Laskos <tasos.laskos@gmail.com>

    This file is part of the SCNR::Engine project and is subject to
    redistribution and commercial restrictions. Please see the SCNR::Engine
    web site for more information on licensing and terms of use.
=end

# Extracts paths from frames.
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
class SCNR::Engine::Parser::Extractors::Frames < SCNR::Engine::Parser::Extractors::Base

    def run
        return [] if !check_for?( 'frame' )

        srcs = []
        document.nodes_by_names( ['frame', 'iframe'] ) { |n| srcs << n['src'] }
        srcs
    end

end
