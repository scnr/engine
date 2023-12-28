=begin
    Copyright 2020-2022 Tasos Laskos <tasos.laskos@gmail.com>

    This file is part of the SCNR::Engine project and is subject to
    redistribution and commercial restrictions. Please see the SCNR::Engine
    web site for more information on licensing and terms of use.
=end

require_relative 'base'

module SCNR::Engine::Element

# @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
class UIForm < Base
    require_relative 'ui_form/dom'

    include SCNR::Engine::Element::Capabilities::DOMOnly

    SUPPORTED_TYPES = %w(input button)

    attr_accessor :opening_tags

    def initialize( options )
        super options

        @opening_tags = (options[:opening_tags] || []).dup
    end

    def dup
        super.tap do |o|
            o.opening_tags = self.opening_tags.dup
        end
    end

    def self.type
        :ui_form
    end

    def self.from_browser( browser, page )
        ui_forms = []

        return ui_forms if !browser.javascript.supported? || !in_html?( page.body )

        # Does the page have any text inputs?
        inputs, opening_tags = inputs_from_page( page )
        return ui_forms if inputs.empty?

        # Looks like we have input groups, get buttons with events.
        browser.each_element_with_events SUPPORTED_TYPES do |locator, events|
            type = locator.attributes['type'].to_s.downcase

            next if locator.tag_name == :input && type != 'button' &&
                type != 'submit'

            events.each do |event, _|
                ui_forms << new(
                    action:       page.url,
                    source:       locator.to_s,
                    method:       event,
                    inputs:       inputs,
                    opening_tags: opening_tags
                )
            end
        end

        ui_forms.uniq
    end

    def self.in_html?( html )
        html.has_html_tag?( 'button' ) ||
            html.has_html_tag?( 'input', /button|submit/ )
    end

    def self.inputs_from_page( page )
        opening_tags = {}
        inputs       = {}

        if UIInput.with_textarea_in_html?( page.body )
            page.document.nodes_by_name( :textarea ) do |textarea|
                name = node_to_name( textarea )

                inputs[name]       = textarea.text
                opening_tags[name] =
                    SCNR::Engine::Browser::ElementLocator.from_node( textarea ).to_s
            end
        end

        if UIInput.with_input_in_html?( page.body )
            page.document.nodes_by_name( :input ) do |input|
                next if input['type'] && input['type'].downcase != 'text'

                name = node_to_name( input )

                inputs[name]       = input['value'].to_s
                opening_tags[name] =
                    SCNR::Engine::Browser::ElementLocator.from_node( input ).to_s
            end
        end

        [inputs, opening_tags]
    end

    def self.node_to_name( node )
        node['name'] || node['id'] ||
            SCNR::Engine::Browser::ElementLocator.from_node( node ).to_s
    end

end
end

SCNR::Engine::UIForm = SCNR::Engine::Element::UIForm
