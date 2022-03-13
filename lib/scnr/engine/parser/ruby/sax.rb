=begin
    Copyright 2020-2022 Tasos Laskos <tasos.laskos@gmail.com>

    This file is part of the SCNR::Engine Framework project and is subject to
    redistribution and commercial restrictions. Please see the SCNR::Engine Framework
    web site for more information on licensing and terms of use.
=end

require_relative 'document'

module SCNR::Engine
class Parser
module Ruby

class SAX < Ox::Sax

    attr_reader :document

    def initialize
        @document     = Document.new
        @current_node = @document
    end

    def start_element( name )
        e = Nodes::Element.new( name )

        @current_node << e
        @current_node  = e
    end

    def end_element( name )
        @current_node = @current_node.parent
    end

    def attr( name, value )
        return if !@current_node.respond_to?( :attributes )

        @current_node.attributes[name] = value
    end

    def text( value )
        value.strip!
        return if value.empty?

        @current_node << Nodes::Text.new( value )
    end

    def comment( value )
        @current_node << Nodes::Comment.new( value )
    end

end

end
end
end
