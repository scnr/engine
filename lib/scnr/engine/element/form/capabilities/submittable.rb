=begin
    Copyright 2020-2022 Tasos Laskos <tasos.laskos@gmail.com>

    This file is part of the SCNR::Engine project and is subject to
    redistribution and commercial restrictions. Please see the SCNR::Engine
    web site for more information on licensing and terms of use.
=end

module SCNR::Engine::Element
class Form
module Capabilities

# Extends {Engine::Element::Capabilities::Submittable} with {Form}-specific
# functionality.
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
module Submittable
    include SCNR::Engine::Element::Capabilities::Submittable

    # @param    (see SCNR::Engine::Element::Capabilities::Submittable#action=)
    # @@return  (see SCNR::Engine::Element::Capabilities::Submittable#action=)
    def action=( url )
        if self.method == :get
            rewritten   = uri_parse( url ).rewrite
            self.inputs = rewritten.query_parameters.merge( self.inputs || {} )

            super rewritten.without_query
        else
            super url
        end
    end

end
end
end
end
