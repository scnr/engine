=begin
    Copyright 2020 Tasos Laskos <tasos.laskos@gmail.com>

    This file is part of the SCNR::Engine project and is subject to
    redistribution and commercial restrictions. Please see the SCNR::Engine
    web site for more information on licensing and terms of use.
=end

# Extracts paths from "link" HTML elements.
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
class SCNR::Engine::Parser::Extractors::Links < SCNR::Engine::Parser::Extractors::Base

    def run
        return [] if !check_for?( 'link' )

        hrefs = []
        document.nodes_by_name( 'link' ) { |l| hrefs << l['href'] }
        hrefs
    end

end
