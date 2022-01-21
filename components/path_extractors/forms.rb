=begin
    Copyright 2020-2022 Tasos Laskos <tasos.laskos@gmail.com>

    This file is part of the SCNR::Engine project and is subject to
    redistribution and commercial restrictions. Please see the SCNR::Engine
    web site for more information on licensing and terms of use.
=end

# Extracts paths from "form" HTML elements.
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
class SCNR::Engine::Parser::Extractors::Forms < SCNR::Engine::Parser::Extractors::Base

    def run
        return [] if !check_for?( 'action' )

        actions = []
        document.nodes_by_name( 'form' ) { |f| actions << f['action'] }
        actions
    end

end
