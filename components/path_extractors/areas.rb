=begin
    Copyright 2020-2022 Tasos Laskos <tasos.laskos@gmail.com>

    This file is part of the SCNR::Engine project and is subject to
    redistribution and commercial restrictions. Please see the SCNR::Engine
    web site for more information on licensing and terms of use.
=end

# Extracts paths from anchor elements.
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
class SCNR::Engine::Parser::Extractors::Areas < SCNR::Engine::Parser::Extractors::Base

    def run
        return [] if !check_for?( 'area' ) || !check_for?( 'href' )

        hrefs = []
        document.nodes_by_name( 'area' ) { |a| hrefs << a['href'] }
        hrefs
    end

end
