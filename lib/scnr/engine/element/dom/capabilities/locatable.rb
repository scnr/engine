=begin
    Copyright 2020 Tasos Laskos <tasos.laskos@gmail.com>

    This file is part of the SCNR::Engine project and is subject to
    redistribution and commercial restrictions. Please see the SCNR::Engine
    web site for more information on licensing and terms of use.
=end

module SCNR::Engine::Element
class DOM
module Capabilities

# @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
module WithLocator

    def locator
        @locator ||= SCNR::Engine::Browser::ElementLocator.from_node( node )
    end

end

end
end
end
