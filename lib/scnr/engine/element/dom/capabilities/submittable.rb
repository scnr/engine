=begin
    Copyright 2020 Tasos Laskos <tasos.laskos@gmail.com>

    This file is part of the SCNR::Engine project and is subject to
    redistribution and commercial restrictions. Please see the SCNR::Engine
    web site for more information on licensing and terms of use.
=end

module SCNR::Engine::Element
class DOM
module Capabilities

# @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
module Submittable
    include SCNR::Engine::Element::Capabilities::Submittable

    def self.included( base )
        base.extend SubmittableClassMethods
    end

    module SubmittableClassMethods
        def prepare_callback( &block )
            lambda do |browser, options|
                prepare_browser( browser, options )
                submit_with_browser( browser, options, &block )
            end
        end

        def prepare_browser( browser, options )
            browser.parse_profile          = (options[:browser] || {})[:parse_profile]
            browser.javascript.custom_code = options[:custom_code]
            browser.javascript.taint       = options[:taint]

            # Depending on element, at this point the DOM may need to be restored.
            # This should be handled by element-specific overrides.
        end

        def submit_with_browser( browser, options, &cb )
            # Depending on element, at this point nonces may need to be updated.
            # This should be handled by element-specific overrides.

            element         = options[:element]
            element.browser = browser
            element.auditor = options[:auditor]

            transitions = element.trigger.compact
            page = browser.to_page
            page.dom.transitions  += transitions
            page.request.performer = element

            cb.call( page ) if block_given?
            page
        end
    end

    def submit( options = {}, method = nil, &block )
        # Remove references to the Auditor instance (the check instance) to
        # remove references to the associated pages and HTTP responses etc.
        #
        # We don't know how long we'll be waiting in the queue so keeping these
        # objects in memory can result in big leaks -- which is why we're also
        # moving to class-level callbacks, to avoid closures capturing context.

        auditor  = @auditor
        @auditor = nil

        options = options.merge(
            element: self,
            auditor: auditor.class,
            dom:     page.dom
        )

        if method
            auditor.with_browser( options, method )
        else
            auditor.with_browser( options, &self.class.prepare_callback( &block ) )
        end

        nil
    end

end

end
end
end
