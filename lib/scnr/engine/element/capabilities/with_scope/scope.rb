=begin
    Copyright 2020 Tasos Laskos <tasos.laskos@gmail.com>

    This file is part of the SCNR::Engine project and is subject to
    redistribution and commercial restrictions. Please see the SCNR::Engine
    web site for more information on licensing and terms of use.
=end

module SCNR::Engine
module Element::Capabilities
module WithScope

# Determines the {Scope scope} status of {Element::Base elements} based on
# their {Element::Base#action} and {Element::Base#type}.
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
class Scope < URICommon::Scope

    # @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
    class Error < URICommon::Scope::Error
    end

    def initialize( element )
        @element = element
        super SCNR::Engine::URI( element.action )
    end

    # @note Will call {URICommon::Scope#redundant?}.
    #
    # @return   (see URICommon::Scope#out?)
    def out?
        begin
            return true if !SCNR::Engine::Options.audit.element?( @element.type )
        rescue SCNR::Engine::OptionGroups::Audit::Error::InvalidElementType
        end

        super || redundant?
    end

end

end
end
end
