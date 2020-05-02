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

class Base

    INDENTATION = 4

    # @private
    attr_accessor :parent

    def free
    end

    def to_s
        to_html
    end

    def text
        txt = children.find { |n| n.is_a? Parser::Nodes::Text }
        return '' if !txt

        txt.value
    end

    def traverse( &block )
        children.each do |node|
            block.call( node )
            node.traverse( &block )
        end
    end

    def traverse_comments( &block )
        descendants.each do |e|
            next if !e.kind_of?( Nodes::Comment )

            block.call e
        end
    end

    def nodes_by_name( name, &block )
        name = name.to_s.downcase

        descendants.each do |e|
            next if !e.respond_to?( :name ) || e.name != name.to_sym

            block.call e
        end
    end

    def nodes_by_names( *names, &block )
        names.flatten.each { |n| nodes_by_name( n, &block ) }
    end

    def nodes_by_attribute_name_and_value( name, value, &block )
        name = name.to_s.downcase

        descendants.each do |e|
            next if !e.respond_to?(:attributes) ||
                !e.attributes.include?( name ) ||
                e.attributes[name].downcase != value.downcase

            block.call e
        end
    end

    # @private
    def <<( child )
        child.parent = self
        children << child
    end

    protected

    def children
        @children ||= []
    end

    private

    def descendants
        @descendants ||= begin
            n = []
            traverse { |e| n << e }
            n
        end
    end

end

end
end
end
end
