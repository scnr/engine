=begin
    Copyright 2020 Alex Douckas <alexdouckas@gmail.com>, Tasos Laskos <tasos.laskos@gmail.com>

    This file is part of the Arachni Framework project and is subject to
    redistribution and commercial restrictions. Please see the Arachni Framework
    web site for more information on licensing and terms of use.
=end

require_relative 'base'
require_relative '../../common/nodes/element/with_attributes'

module SCNR::Engine
class Parser
module Ruby
module Nodes

class Element < Base
    include Common::Nodes::Element::WithAttributes

    attr_reader :name

    def initialize( name )
        super()

        @name = name.downcase.to_sym
    end

    def to_html( level = 0 )
        indent = ' ' * (INDENTATION * level)

        html = "#{indent}<#{name}"

        attributes.each do |k, v|
            html << " #{k}=#{v.inspect}"
        end

        html << ">\n"
        children.each do |node|
            html << node.to_html( level + 1  )
        end
        html << "#{indent}</#{name}>\n"
    end

end

end
end
end
end
