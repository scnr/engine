=begin
    Copyright 2020 Tasos Laskos <tasos.laskos@gmail.com>

    This file is part of the SCNR::Engine project and is subject to
    redistribution and commercial restrictions. Please see the SCNR::Engine
    web site for more information on licensing and terms of use.
=end

class SCNR::Engine::Element::Form::DOM
module Capabilities

# Extends {Engine::Element::DOM::Capabilities::Submittable} with
# {Form}-specific functionality.
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
module Submittable
    include SCNR::Engine::Element::DOM::Capabilities::Submittable

    def self.included( base )
        base.extend SCNR::Engine::Element::DOM::Capabilities::Submittable::SubmittableClassMethods
        base.extend ClassMethods
    end

    module ClassMethods
        def prepare_browser( browser, options )
            super( browser, options )

            browser.load options[:dom]
        end

        def submit_with_browser( browser, options, &cb )
            element = options[:element]

            # Update nonces.
            if element.updated?
                fresh_inputs = browser.javascript.dom_monitor.element_inputs( element.locator.css )

                # There's a chance that the form could not be found this time
                # around so don't get tripped up.
                # And if the form could not be found, it will be handled down the line.
                if fresh_inputs
                    element.inputs = fresh_inputs.merge( element.changes )
                end
            end

            super( browser, options, &cb )
        end
    end

end
end
end
