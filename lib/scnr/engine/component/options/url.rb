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
