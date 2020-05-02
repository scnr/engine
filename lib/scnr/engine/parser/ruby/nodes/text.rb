=begin
    Copyright 2020 Tasos Laskos <tasos.laskos@gmail.com>

    This file is part of the Arachni Framework project and is subject to
    redistribution and commercial restrictions. Please see the Arachni Framework
    web site for more information on licensing and terms of use.
=end

require_relative 'base'
require_relative 'with_cdata'

module SCNR::Engine
class Parser
module Ruby
module Nodes

class Text < Base
    include WithCData

    def to_html( level = 0 )
        indent = ' ' * (INDENTATION * level)
        "#{indent}#{text}\n"
    end

end

end
end
end
end
