=begin
    Copyright 2020 Alex Douckas <alexdouckas@gmail.com>, Tasos Laskos <tasos.laskos@gmail.com>

    This file is part of the SCNR::Engine project and is subject to
    redistribution and commercial restrictions. Please see the SCNR::Engine
    web site for more information on licensing and terms of use.
=end

require_relative '../dom'

module SCNR::Engine::Element
class LinkTemplate

# Provides access to DOM operations for {LinkTemplate link templates}.
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
class DOM < DOM
    include SCNR::Engine::Element::Capabilities::WithNode
    include SCNR::Engine::Element::DOM::Capabilities::WithSinks
    include SCNR::Engine::Element::DOM::Capabilities::WithLocator
    include SCNR::Engine::Element::DOM::Capabilities::Mutable
    include SCNR::Engine::Element::DOM::Capabilities::Inputtable
    include SCNR::Engine::Element::DOM::Capabilities::Submittable
    include SCNR::Engine::Element::DOM::Capabilities::Auditable

    # @return   [String, nil]
    #   URL fragment.
    #
    #   `http://test.com/stuff#/path/in/fragment?with-input=too` =>
    #   `/path/in/fragment?with-input=too`
    attr_reader :fragment

    # @return    [Regexp]
    #   Regular expressions with named captures, serving as templates used to
    #   identify and manipulate inputs in {#action}.
    attr_reader :template

    def initialize(*)
        super

        prepare_data_from_node
        @method = :get
    end

    # Loads {#to_s}.
    def trigger
        [ browser.goto( to_s, update_transitions: false ) ]
    end

    # @param    [String]    name
    #   Input name.
    #
    # @return   [Bool]
    #   `true` if the `name` can be found as a named capture in {#template},
    #   `false` otherwise.
    def valid_input_name?( name )
        return if !@template
        @template.names.include? name
    end

    # @return   [String]
    #   {#action} updated with the the DOM {#inputs}.
    def to_s
        "#{@action}#" + fragment.sub_in_groups( @template, inputs )
    end

    def message_action
        "#{@action}##{fragment}"
    end

    def extract_inputs( *args )
        self.class.extract_inputs( *args )
    end
    def self.extract_inputs( url, templates = SCNR::Engine::Options.audit.link_template_doms )
        LinkTemplate.extract_inputs( url, templates )
    end

    def type
        self.class.type
    end

    def self.type
        :link_template_dom
    end

    def self.data_from_node( node )
        href = node['href'].to_s
        return if !href.include? '#'

        fragment = Link.decode( href.split( '#', 2 ).last.to_s )

        template, inputs = extract_inputs( fragment )
        return if !template || !inputs || inputs.empty?

        {
            inputs:   inputs,
            template: template,
            fragment: fragment
        }
    end

    def hash
        to_s.hash
    end

    def to_rpc_data
        super.merge( 'template' => @template.source )
    end

    def self.from_rpc_data( data )
        super data.merge( 'template' => Regexp.new( data['template'] ) )
    end

    private

    def prepare_data_from_node
        return if !(data = self.class.data_from_node( node ))

        @template   = data[:template]
        self.inputs = data[:inputs]
        @fragment   = data[:fragment]

        @default_inputs = self.inputs.dup.freeze
    end

    def prepare_browser( browser, options )
        @browser = browser
        browser.javascript.custom_code = options[:custom_code]
        browser.javascript.taint       = options[:taint]
    end

end

end
end
