=begin
    Copyright 2020 Alex Douckas <alexdouckas@gmail.com>, Tasos Laskos <tasos.laskos@gmail.com>

    This file is part of the SCNR::Engine project and is subject to
    redistribution and commercial restrictions. Please see the SCNR::Engine
    web site for more information on licensing and terms of use.
=end

require_relative '../dom'

module SCNR::Engine::Element
class Form

# Extends {SCNR::Engine::Element::Capabilities::Auditable::DOM} with {Form}-specific
# functionality.
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
class DOM < DOM

    # Load and include all form-specific capability overrides.
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

        inputs = (options[:inputs] || self.parent.inputs).dup
        @valid_input_names = inputs.keys.map(&:to_s)

        self.inputs     = inputs
        @default_inputs = self.inputs.dup.freeze
    end

    # Submits the form using the configured {#inputs}.
    def trigger
        [ browser.fire_event( locator, :submit, inputs: inputs.dup ) ]
    end

    def valid_input_name?( name )
        @valid_input_names.include? name.to_s
    end

    def type
        self.class.type
    end
    def self.type
        :form_dom
    end

    def initialization_options
        super.merge( inputs: inputs.dup )
    end

end

end
end
