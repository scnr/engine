=begin
    Copyright 2024 Ecsypno Single Member P.C.

    This file is part of the SCNR::Engine project and is subject to
    redistribution and commercial restrictions. Please see the SCNR::Engine
    web site for more information on licensing and terms of use.
=end

require_relative '../dom'

module SCNR::Engine::Element
class UIInput

# @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
class DOM < DOM
    # Load and include all UI-form-specific capability overrides.
    lib = "#{File.dirname( __FILE__ )}/#{File.basename(__FILE__, '.rb')}/capabilities/**/*.rb"
    Dir.glob( lib ).each { |f| require f }

    include SCNR::Engine::Element::Capabilities::WithNode
    include SCNR::Engine::Element::DOM::Capabilities::WithSinks
    include SCNR::Engine::Element::DOM::Capabilities::WithLocator
    include SCNR::Engine::Element::DOM::Capabilities::Mutable
    include SCNR::Engine::Element::DOM::Capabilities::Inputtable
    include SCNR::Engine::Element::DOM::Capabilities::Auditable

    include Capabilities::Submittable

    def initialize( options )
        super

        self.method = options[:method] || self.parent.method

        if options[:inputs]
            @valid_input_name = options[:inputs].keys.first.to_s
            self.inputs       = options[:inputs]
        else
            @valid_input_name = (locator.attributes['name'] || locator.attributes['id']).to_s
            self.inputs       = {
                @valid_input_name => locator.attributes['value']
            }
        end

        @default_inputs = self.inputs.dup.freeze
    end

    # Submits the form using the configured {#inputs}.
    def trigger
        [ browser.fire_event( locator, @method, value: value ) ]
    end

    def name
        inputs.keys.first
    end

    def value
        inputs.values.first
    end

    def valid_input_name?( name )
        @valid_input_name == name.to_s
    end

    def coverage_id
        "#{super}:#{@method}:#{locator.hash}"
    end

    def id
        "#{super}:#{@method}:#{locator.hash}"
    end

    def type
        self.class.type
    end
    def self.type
        :ui_input_dom
    end

    def initialization_options
        super.merge( inputs: inputs.dup, method: @method )
    end

end
end
end
