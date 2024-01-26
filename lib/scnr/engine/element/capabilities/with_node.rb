=begin
    Copyright 2024 Ecsypno Single Member P.C.

    This file is part of the SCNR::Engine project and is subject to
    redistribution and commercial restrictions. Please see the SCNR::Engine
    web site for more information on licensing and terms of use.
=end

require_relative 'with_source'

module SCNR::Engine
module Element::Capabilities

# @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
module WithNode
    include WithSource

    def node
        return if !@source
        SCNR::Engine::Parser.parse_fragment( @source )
    end

end

end
end
