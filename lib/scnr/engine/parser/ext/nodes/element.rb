=begin
    Copyright 2020 Tasos Laskos <tasos.laskos@gmail.com>

    This file is part of the SCNR::Engine project and is subject to
    redistribution and commercial restrictions. Please see the SCNR::Engine
    web site for more information on licensing and terms of use.
=end

require_relative 'base'
require_relative '../../common/nodes/element/with_attributes'

module SCNR::Engine
class Parser
module Ext
module Nodes

class Element < Base
    include Common::Nodes::Element::WithAttributes

    def initialize(*)
        super

        attributes.update( @native.attributes )
    end

    def name
        @native.name
    end

end

end
end
end
end
