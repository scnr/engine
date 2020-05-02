=begin
    Copyright 2020 Tasos Laskos <tasos.laskos@gmail.com>

    This file is part of the SCNR::Engine project and is subject to
    redistribution and commercial restrictions. Please see the SCNR::Engine
    web site for more information on licensing and terms of use.
=end

module SCNR::Engine::Element
class Cookie

module Capabilities

# Extends {SCNR::Engine::Element::Capabilities::WithDOM} with {Cookie}-specific
# functionality.
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
module WithDOM
    include SCNR::Engine::Element::Capabilities::WithDOM

    def skip_dom?
        # Don't assume a DOM component for cookies unless explicitly set.
        @skip_dom.nil? || @skip_dom
    end

end

end
end
end
