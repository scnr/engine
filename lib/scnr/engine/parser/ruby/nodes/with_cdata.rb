=begin
    Copyright 2020 Tasos Laskos <tasos.laskos@gmail.com>

    This file is part of the Arachni Framework project and is subject to
    redistribution and commercial restrictions. Please see the Arachni Framework
    web site for more information on licensing and terms of use.
=end

module SCNR::Engine
class Parser
module Ruby
module Nodes

module WithCData

    def initialize( cdata )
        @cdata = cdata.to_s.recode.strip.freeze
    end

    def text
        @cdata
    end
    alias :value :text

end

end
end
end
end
