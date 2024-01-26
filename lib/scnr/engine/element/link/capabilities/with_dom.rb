=begin
    Copyright 2024 Ecsypno Single Member P.C.

    This file is part of the SCNR::Engine project and is subject to
    redistribution and commercial restrictions. Please see the SCNR::Engine
    web site for more information on licensing and terms of use.
=end

module SCNR::Engine::Element
class Link
module Capabilities

# Extends {Engine::Element::Capabilities::WithDOM} with {Link}-specific
# functionality.
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
module WithDOM
    include SCNR::Engine::Element::Capabilities::WithDOM

    # @return   [DOM]
    def dom
        return @dom if @dom
        return if !dom_data

        super
    end

    private

    def dom_data
        return if !@source
        return @dom_data if @dom_data
        return if @dom_data == false

        # Don't bother parsing the source if it doesn't have anything interesting.
        if !/href=['"]?.*#.*\?.*=.*?>/mi.match?( @source )
            return @dom_data = false
        end

        return if !node

        @dom_data ||= (self.class::DOM.data_from_node( node ) || false)
    end

end

end
end
end
