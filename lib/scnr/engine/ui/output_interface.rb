=begin
    Copyright 2020 Tasos Laskos <tasos.laskos@gmail.com>

    This file is part of the SCNR::Engine project and is subject to
    redistribution and commercial restrictions. Please see the SCNR::Engine
    web site for more information on licensing and terms of use.
=end

require 'scnr/engine/error'

module SCNR::Engine
module UI

# @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
class Error < SCNR::Engine::Error
end

# @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
module OutputInterface

    # @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
    class Error < SCNR::Engine::UI::Error
    end

    require_relative 'output_interface/abstract'
    require_relative 'output_interface/implemented'

    require_relative 'output_interface/error_logging'
    require_relative 'output_interface/controls'
    require_relative 'output_interface/personalization'

    # These output methods need to be implemented by the driving UI.
    include Abstract
    # These output method implementations depend on the Abstract ones.
    include Implemented

    include ErrorLogging
    include Controls
    include Personalization

    # Must be called after the entire {SCNR::Engine} environment has been loaded.
    def self.initialize
        Controls.initialize
        ErrorLogging.initialize
    end

    extend self
end

end
end
