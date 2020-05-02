=begin
    Copyright 2020 Tasos Laskos <tasos.laskos@gmail.com> 

    This file is part of the SCNR::Engine project and is subject to
    redistribution and commercial restrictions. Please see the SCNR::Engine
    web site for more information on licensing and terms of use.
=end

module SCNR::Engine::Element
class LinkTemplate
module Capabilities

# Extends {Engine::Element::Capabilities::Auditable} with {LinkTemplate}-specific
# functionality.
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
module Auditable
    include SCNR::Engine::Element::Capabilities::Auditable

    def coverage_id
        dom_data ? "#{super}:#{dom_data[:inputs].keys.sort}" : super
    end

end
end
end
end
