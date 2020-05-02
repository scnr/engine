=begin
    Copyright 2020 Alex Douckas <alexdouckas@gmail.com>, Tasos Laskos <tasos.laskos@gmail.com>

    This file is part of the SCNR::Engine project and is subject to
    redistribution and commercial restrictions. Please see the SCNR::Engine
    web site for more information on licensing and terms of use.
=end

module SCNR::Engine
class Framework
module Parts

# Provides access to {SCNR::Engine::Platform} helpers.
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
module Platform

    # @return    [Array<Hash>]
    #   Information about all available platforms.
    def list_platforms
        platforms = SCNR::Engine::Platform::Manager.new
        platforms.valid.inject({}) do |h, platform|
            type = SCNR::Engine::Platform::Manager::TYPES[platforms.find_type( platform )]
            h[type] ||= {}
            h[type][platform] = platforms.fullname( platform )
            h
        end
    end

end

end
end
end
