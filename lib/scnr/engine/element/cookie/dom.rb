=begin
    Copyright 2024 Ecsypno Single Member P.C.

    This file is part of the SCNR::Engine project and is subject to
    redistribution and commercial restrictions. Please see the SCNR::Engine
    web site for more information on licensing and terms of use.
=end

require_relative '../dom'

module SCNR::Engine::Element
class Cookie

# Provides access to DOM operations for {Cookie cookies}.
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
class DOM < DOM
    include SCNR::Engine::Element::DOM::Capabilities::WithSinks
    include SCNR::Engine::Element::DOM::Capabilities::Mutable
    include SCNR::Engine::Element::DOM::Capabilities::Inputtable
    include SCNR::Engine::Element::DOM::Capabilities::Submittable
    include SCNR::Engine::Element::DOM::Capabilities::Auditable

    def initialize( options )
        super

        self.inputs     = (options[:inputs] || self.parent.inputs).dup
        @default_inputs = self.inputs.dup.freeze
    end

    # Submits the cookie using the configured {#inputs}.
    def trigger
        [ browser.goto(
            action,
            cookies:            self.inputs,
            update_transitions: false
        ) ]
    end

    def name
        inputs.keys.first
    end

    def value
        inputs.values.first
    end

    def to_set_cookie
        p = parent.dup
        p.inputs = inputs
        p.to_set_cookie
    end

    def type
        self.class.type
    end
    def self.type
        :cookie_dom
    end

    def initialization_options
        super.merge( inputs: inputs.dup )
    end

end

end
end
