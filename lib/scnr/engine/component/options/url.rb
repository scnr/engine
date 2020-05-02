=begin
    Copyright 2020 Tasos Laskos <tasos.laskos@gmail.com>

    This file is part of the SCNR::Engine project and is subject to
    redistribution and commercial restrictions. Please see the SCNR::Engine
    web site for more information on licensing and terms of use.
=end

# URL option.
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
class SCNR::Engine::Component::Options::URL < SCNR::Engine::Component::Options::Base

    def normalize
        SCNR::Engine::URI( effective_value )
    end

    def valid?
        return false if !super

        normalized = normalize
        return false if !normalized
        return false if !normalized.absolute?

        !!IPSocket.getaddress( normalized.host ) rescue false
    end

    def type
        :url
    end

end
