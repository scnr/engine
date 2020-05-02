=begin
    Copyright 2020 Tasos Laskos <tasos.laskos@gmail.com>

    This file is part of the SCNR::Engine project and is subject to
    redistribution and commercial restrictions. Please see the SCNR::Engine
    web site for more information on licensing and terms of use.
=end

module SCNR::Engine
module HTTP
class Client
class Soft404
class Handler
module Parts

module HTTP

    private

    def request( url, &block )
        Client.get( url,
            # This is important, helps us reduce waiting callers.
            high_priority:   true,

            # We're going to be checking for a lot of non-existent resources,
            # don't bother fingerprinting them
            fingerprint:     false,

            follow_location: true,

            performer:       self,
            &block
        )
    end

    # If this is neither a regular 404 nor a 202 the server probably freaked out
    # -- 500 errors under stress and the like.
    #
    # In that case we should bail out to avoid corrupted signatures which can
    # lead to FPs.
    def corrupted_response?( response )
        !response.ok? || (response.code != 404 && response.code != 200)
    end

end

end
end
end
end
end
end
