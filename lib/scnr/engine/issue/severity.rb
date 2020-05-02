=begin
    Copyright 2020 Tasos Laskos <tasos.laskos@gmail.com>

    This file is part of the SCNR::Engine project and is subject to
    redistribution and commercial restrictions. Please see the SCNR::Engine
    web site for more information on licensing and terms of use.
=end

module SCNR::Engine

require Options.paths.lib + 'issue/severity/base'

class Issue

# Holds different severity levels.
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
module Severity

    ORDER = [
        :high,
        :medium,
        :low,
        :informational
    ]

    HIGH          = Base.new( :high )
    MEDIUM        = Base.new( :medium )
    LOW           = Base.new( :low )
    INFORMATIONAL = Base.new( :informational )

end
end
end

SCNR::Engine::Severity = SCNR::Engine::Issue::Severity
