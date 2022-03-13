=begin
    Copyright 2020-2022 Tasos Laskos <tasos.laskos@gmail.com>

    This file is part of the SCNR::Engine Framework project and is subject to
    redistribution and commercial restrictions. Please see the SCNR::Engine Framework
    web site for more information on licensing and terms of use.
=end

module SCNR::Engine
class Parser
module Ruby
module Nodes

module WithCData

    def initialize( cdata )
        @cdata = cdata
        @cdata.recode!
        @cdata.strip!
        @cdata.freeze
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
