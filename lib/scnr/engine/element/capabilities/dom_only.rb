=begin
    Copyright 2020-2022 Tasos Laskos <tasos.laskos@gmail.com>

    This file is part of the SCNR::Engine project and is subject to
    redistribution and commercial restrictions. Please see the SCNR::Engine
    web site for more information on licensing and terms of use.
=end

require_relative '../base'
require_relative 'with_node'
require_relative 'with_dom'

module SCNR::Engine
module Element::Capabilities

# @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
module DOMOnly
    include SCNR::Engine::Element::Capabilities::WithAuditor
    include SCNR::Engine::Element::Capabilities::Inputtable
    include SCNR::Engine::Element::Capabilities::WithNode
    include SCNR::Engine::Element::Capabilities::WithDOM

    attr_accessor :method

    def initialize( options )
        super options

        @method   = options[:method]

        self.inputs = options[:inputs]
        @default_inputs = self.inputs.dup.freeze
    end

    def mutation?
        false
    end

    def coverage_id
        "#{type}:#{dom.coverage_id}"
    end

    def coverage_hash
        coverage_id.persistent_hash
    end

    def id
        "#{type}:#{dom.id}"
    end

    def dup
        super.tap do |o|
            o.method = self.method
        end
    end

    def type
        self.class.type
    end

end
end
end
