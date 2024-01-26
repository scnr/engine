=begin
    Copyright 2024 Ecsypno Single Member P.C.

    This file is part of the SCNR::Engine project and is subject to
    redistribution and commercial restrictions. Please see the SCNR::Engine
    web site for more information on licensing and terms of use.
=end

# @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
class SCNR::Engine::Parser::Extractors::BaseElem < SCNR::Engine::Parser::Extractors::Base

    def run
        return [] if !check_for?( 'base' ) || !check_for?( 'base' )

        hrefs = []
        document.nodes_by_name( 'base' ) { |b| hrefs << b['href'] }
        hrefs
    end

end
