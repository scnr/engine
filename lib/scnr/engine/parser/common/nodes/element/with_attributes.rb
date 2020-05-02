=begin
    Copyright 2020 Tasos Laskos <tasos.laskos@gmail.com> 

    This file is part of the SCNR::Engine project and is subject to
    redistribution and commercial restrictions. Please see the SCNR::Engine
    web site for more information on licensing and terms of use.
=end

require_relative 'with_attributes/attributes'

module SCNR::Engine
class Parser
module Common
module Nodes
class Element

module WithAttributes

    def attributes
        @attributes ||= Attributes.new
    end

    def []( name )
        attributes[name]
    end

end

end
end
end
end
end
