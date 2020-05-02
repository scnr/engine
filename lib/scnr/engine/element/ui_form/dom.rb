=begin
    Copyright 2020 Alex Douckas <alexdouckas@gmail.com>, Tasos Laskos <tasos.laskos@gmail.com> 

    This file is part of the SCNR::Engine project and is subject to
    redistribution and commercial restrictions. Please see the SCNR::Engine
    web site for more information on licensing and terms of use.
=end

require_relative '../dom'

module SCNR::Engine::Element
class UIForm

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

    INPUTS = Set.new([:input, :textarea])

    def initialize( options )
        super

        @opening_tags = (options[:opening_tags] || parent.opening_tags).dup

        self.method = options[:method] || self.parent.method

        inputs = (options[:inputs] || self.parent.inputs ).dup

        @valid_input_names = Set.new(inputs.keys)
        self.inputs        = inputs

        @default_inputs = self.inputs.dup.freeze
    end

    # Submits the form using the configured {#inputs}.
    def trigger
        transitions = fill_in_inputs

        print_debug "Submitting: #{self.source}"
        submission_transition = browser.fire_event( locator, @method )
        print_debug "Submitted: #{self.source}"

        return [] if !submission_transition

        transitions + [submission_transition]
    end

    def valid_input_name?( name )
        @valid_input_names.include? name.to_s
    end

    def coverage_id
        "#{super}:#{@method}:#{locator}"
    end

    def id
        "#{super}:#{@method}:#{locator}"
    end

    def type
        self.class.type
    end
    def self.type
        :ui_form_dom
    end

    def initialization_options
        super.merge(
            inputs:       inputs.dup,
            method:       @method,
            opening_tags: @opening_tags.dup
        )
    end

    def marshal_dump
        super.tap { |h| h.delete :@valid_input_names }
    end

    private

    def fill_in_inputs
        transitions = []

        @inputs.each do |name, value|
            locator     = locator_for_input( name )
            opening_tag = @opening_tags[name]

            print_debug "Filling in: #{name} => #{value} [#{opening_tag}]"

            t = browser.fire_event( locator, :input, value: value )

            if !t
                print_debug "Could not fill in: #{name} => #{value} [#{opening_tag}]"
                next
            end
            print_debug "Filled in: #{name} => #{value} [#{opening_tag}]"

            transitions << t
        end

        transitions
    end

    def locator_for_input( name )
        SCNR::Engine::Browser::ElementLocator.from_html @opening_tags[name]
    end

end
end
end
