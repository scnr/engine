=begin
    Copyright 2024 Ecsypno Single Member P.C.

    This file is part of the SCNR::Engine project and is subject to
    redistribution and commercial restrictions. Please see the SCNR::Engine
    web site for more information on licensing and terms of use.
=end

require_relative 'base'

module SCNR::Engine::Element

# @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
class UIInput < Base
    require_relative 'ui_input/dom'

    include SCNR::Engine::Element::Capabilities::DOMOnly

    SUPPORTED_TYPES = %w(input textarea)

    def self.type
        :ui_input
    end

    def self.from_browser( browser, page )
        inputs = []

        return inputs if !browser.javascript.supported? || !in_html?( page.body )

        browser.each_element_with_events SUPPORTED_TYPES do |locator, events|
            next if locator.attributes['type'] && (locator.attributes['type'] != 'text' &&
              locator.attributes['type'] != 'input')

            events.each do |event, _|
                name = locator.attributes['name'] || locator.attributes['id'] ||
                    locator.to_s

                inputs << new(
                    action: page.url,
                    source: locator.to_s,
                    method: event,
                    inputs: {
                        name => locator.attributes['value'].to_s
                    }
                )
            end
        end

        inputs.uniq
    end

    def self.in_html?( html )
        with_textarea_in_html?( html ) || with_input_in_html?( html )
    end

    def self.with_textarea_in_html?( html )
        html.has_html_tag?( 'textarea' )
    end

    def self.with_input_in_html?( html )
        html.has_html_tag?( 'input', /text|(?!type=)/ )
    end

end
end

SCNR::Engine::UIInput = SCNR::Engine::Element::UIInput
