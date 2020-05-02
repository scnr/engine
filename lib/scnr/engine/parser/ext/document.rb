=begin
    Copyright 2020 Alex Douckas <alexdouckas@gmail.com>, Tasos Laskos <tasos.laskos@gmail.com>

    This file is part of the SCNR::Engine project and is subject to
    redistribution and commercial restrictions. Please see the SCNR::Engine
    web site for more information on licensing and terms of use.
=end

require_relative 'nodes/comment'
require_relative 'nodes/text'
require_relative 'nodes/element'

module SCNR::Engine
class Parser
module Ext

class Document < Nodes::Base

    def name
        :document
    end

    def self.parse( html, filter = false )
        new NodeExt.parse( html, filter )
    end

end

end
end
end
