=begin
    Copyright 2020-2022 Tasos Laskos <tasos.laskos@gmail.com>

    This file is part of the Arachni Framework project and is subject to
    redistribution and commercial restrictions. Please see the Arachni Framework
    web site for more information on licensing and terms of use.
=end

require_relative 'nodes/comment'
require_relative 'nodes/text'
require_relative 'nodes/element'
require_relative 'sax'

module SCNR::Engine
class Parser
module Ruby

class Document < Nodes::Base

    WHITELIST = %w(
        title base a form frame iframe meta input select option script link area
        textarea input select button comment !--
    )

    def name
        :document
    end

    def to_html( level = 0 )
        html = "<!DOCTYPE html>\n"
        children.each do |child|
            html << child.to_html( level )
        end
        html << "\n"
    end

    def self.parse( html, filter = false )
        options = {}
        if filter
            options[:whitelist] = WHITELIST
        end

        Parser.sax_parse( SAX.new, html, options ).document
    end

end

end
end
end
