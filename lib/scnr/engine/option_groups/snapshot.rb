=begin
    Copyright 2024 Ecsypno Single Member P.C.

    This file is part of the SCNR::Engine project and is subject to
    redistribution and commercial restrictions. Please see the SCNR::Engine
    web site for more information on licensing and terms of use.
=end

require_relative 'report'

module SCNR::Engine::OptionGroups

# @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
class Snapshot < Report

    def default_path
        Paths.new.snapshots
    end

end
end
