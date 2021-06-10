require 'socket'

# Network address option.
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
class SCNR::Engine::Component::Options::Address < SCNR::Engine::Component::Options::Base

    def valid?
        return false if !super
        !!IPSocket.getaddress( effective_value ) rescue false
    end

    def type
        :address
    end

end
