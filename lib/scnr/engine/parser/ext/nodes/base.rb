=begin
    Copyright 2024 Ecsypno Single Member P.C.

    This file is part of the SCNR::Engine project and is subject to
    redistribution and commercial restrictions. Please see the SCNR::Engine
    web site for more information on licensing and terms of use.
=end

module SCNR::Engine
class Parser
module Ext
module Nodes

class Base

    def initialize( native )
        @native = native
    end

    def free
        # @native.free
    end

    def to_html
        @native.to_html
    end
    alias :to_s :to_html

    def text
        @native.text
    end

    def traverse( &block )
        @native.traverse (proc do |native|
            node = Nodes::Base.from_native( native )
            block.call node
            # native.free
        end)
        nil
    end

    def traverse_comments( &block )
        @native.traverse_comments (proc do |native|
            node = Nodes::Base.from_native( native )
            block.call node
            # native.free
        end)
        nil
    end

    def nodes_by_name( name, &block )
        @native.nodes_by_name name.to_s, (proc do |native|
            node = Nodes::Base.from_native( native )
            block.call node
            # native.free
        end)
        nil
    end

    def nodes_by_names( *names, &block  )
        names.flatten.each { |n| nodes_by_name( n, &block ) }
        nil
    end

    def nodes_by_attribute_name_and_value( name, value, &block )
        name  = name.to_s
        value = value.to_s

        @native.nodes_by_attribute_name_and_value name, value, (proc do |native|
            node = Nodes::Base.from_native( native )
            block.call node
            # native.free
        end)
        nil
    end

    def hash
        to_s.hash
    end

    def ==( other )
        hash == other.hash
    end

    def self.from_native( native )
        case native.type
            when :element
                Element.new( native )

            when :comment
                Comment.new( native )

            when :text
                Text.new( native )
        end
    end

end

end
end
end
end
