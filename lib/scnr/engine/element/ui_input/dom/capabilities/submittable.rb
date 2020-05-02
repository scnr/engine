=begin
    Copyright 2020 Tasos Laskos <tasos.laskos@gmail.com>

    This file is part of the SCNR::Engine project and is subject to
    redistribution and commercial restrictions. Please see the SCNR::Engine
    web site for more information on licensing and terms of use.
=end

class SCNR::Engine::Element::UIInput::DOM
module Capabilities

# Extends {Engine::Element::DOM::Capabilities::Submittable} with
# {UIInput}-specific functionality.
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
    end

end
end
end
