=begin
    Copyright 2024 Ecsypno Single Member P.C.

    This file is part of the SCNR::Engine project and is subject to
    redistribution and commercial restrictions. Please see the SCNR::Engine
    web site for more information on licensing and terms of use.
=end

module SCNR::Engine::Element
class Link
module Capabilities

# Extends {Engine::Element::Capabilities::Submittable} with {Link}-specific
# functionality.
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
module Submittable
    include SCNR::Engine::Element::Capabilities::Submittable

    # @note Will {Engine::URICommon#rewrite} the `url`.
    # @note Will update the {SCNR::Engine::Element::Capabilities::Inputtable#inputs}
    #   from the URL query.
    #
    # @param   (see SCNR::Engine::Element::Capabilities::Submittable#action=)
    #
    # @return  (see SCNR::Engine::Element::Capabilities::Submittable#action=)
    def action=( url )
        rewritten   = uri_parse( url ).rewrite
        self.inputs = rewritten.query_parameters.merge( self.inputs || {} )

        super rewritten.without_query
    end

end
end
end
end
