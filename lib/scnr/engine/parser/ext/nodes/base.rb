=begin
    Copyright 2020 Alex Douckas <alexdouckas@gmail.com>, Tasos Laskos <tasos.laskos@gmail.com>

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
        if @traverse
            @traverse.each( &block )
            return
        end
        @traverse = []

        @native.traverse (proc do |native|
            node = Nodes::Base.from_native( native )
            @traverse << node
            block.call node
            # native.free
        end)
    end

    def traverse_comments( &block )
        if @traverse_comments
            @traverse_comments.each( &block )
            return
        end
        @traverse_comments = []

        @native.traverse_comments (proc do |native|
            node = Nodes::Base.from_native( native )
            @traverse_comments << node
            block.call node
            # native.free
        end)
    end

    def nodes_by_name( name, &block )
        name = name.to_s
        @nodes_by_name ||= {}

        k = name.hash
        if @nodes_by_name.include?( k )
            @nodes_by_name[k].each( &block )
            return
        end
        @nodes_by_name[k] = []

        @native.nodes_by_name name, (proc do |native|
            node = Nodes::Base.from_native( native )
            @nodes_by_name[k] << node
            block.call node
            # native.free
        end)
    end

    def nodes_by_names( *names, &block  )
        names.flatten.each { |n| nodes_by_name( n, &block ) }
    end

    def nodes_by_attribute_name_and_value( name, value, &block )
        name  = name.to_s
        value = value.to_s

        @nodes_by_attribute_name_and_value ||= {}

        k = [name, value].hash
        if @nodes_by_attribute_name_and_value.include?( k )
            @nodes_by_attribute_name_and_value[k].each( &block )
            return
        end
        @nodes_by_attribute_name_and_value[k] = []

        @native.nodes_by_attribute_name_and_value name, value, (proc do |native|
            node = Nodes::Base.from_native( native )
            @nodes_by_attribute_name_and_value[k] << node
            block.call node
            # native.free
        end)
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
