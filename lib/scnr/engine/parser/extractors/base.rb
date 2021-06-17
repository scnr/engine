=begin
    Copyright 2020 Alex Douckas <alexdouckas@gmail.com>, Tasos Laskos <tasos.laskos@gmail.com> 

    This file is part of the SCNR::Engine project and is subject to
    redistribution and commercial restrictions. Please see the SCNR::Engine
    web site for more information on licensing and terms of use.
=end

module SCNR::Engine
class Parser
module Extractors

# @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
# @abstract
class Base
    include SCNR::Engine

    attr_reader :html
    attr_reader :parser
    attr_reader :downcased_html

    def initialize( options = {} )
        @html           = options[:html]
        @downcased_html = @html.downcase if @html
        @parser         = options[:parser]
    end

    # This method must be implemented by all checks and must return an
    # array of paths as plain strings
    #
    # @return   [Array<String>]  paths
    # @abstract
    def run
    end

    def check_for?( substring )
        return true if !@html
        !!@downcased_html.optimized_include?( substring )
    end

    def document
        parser.document
    end

end

end
end
end
