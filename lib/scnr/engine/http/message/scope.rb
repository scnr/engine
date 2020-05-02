=begin
    Copyright 2020 Alex Douckas <alexdouckas@gmail.com>, Tasos Laskos <tasos.laskos@gmail.com> 

    This file is part of the SCNR::Engine project and is subject to
    redistribution and commercial restrictions. Please see the SCNR::Engine
    web site for more information on licensing and terms of use.
=end

module SCNR::Engine
module HTTP
class Message

# Determines the {Scope scope} status of {Message}s.
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
class Scope < URICommon::Scope

    # {Scope} error namespace.
    #
    # All {Scope} errors inherit from and live under it.
    #
    # @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
    class Error < URICommon::Scope::Error
    end

    # @param    [SCNR::Engine::HTTP::Message]  message
    def initialize( message )
        super message.parsed_url
    end

end

end
end
end
