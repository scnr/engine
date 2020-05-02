=begin
    Copyright 2020 Tasos Laskos <tasos.laskos@gmail.com>

    This file is part of the SCNR::Engine project and is subject to
    redistribution and commercial restrictions. Please see the SCNR::Engine
    web site for more information on licensing and terms of use.
=end

require SCNR::Engine::Options.paths.lib + 'element/base'

module SCNR::Engine::Element

# Represents an auditable path element, currently a placeholder for a vulnerable
# path vector.
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
class Path < Base
    include Capabilities::WithAuditor

    def initialize( url )
        super url: url
        @initialization_options = url
    end

    def action
        url
    end

end
end
