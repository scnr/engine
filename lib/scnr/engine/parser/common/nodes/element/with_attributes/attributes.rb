=begin
    Copyright 2024 Ecsypno Single Member P.C.

    This file is part of the SCNR::Engine project and is subject to
    redistribution and commercial restrictions. Please see the SCNR::Engine
    web site for more information on licensing and terms of use.
=end

module SCNR::Engine
class Parser
module Common
module Nodes
class Element
module WithAttributes

class Attributes < Hash

    def initialize( h = {} )
        update( h )
    end

    def []( name )
        super name
    end

    def []=( name, value )
        super name.freeze, value.freeze
    end

    def update( h )
        h.each do |k, v|
            self[k] = v
        end
    end

end

end
end
end
end
end
end
