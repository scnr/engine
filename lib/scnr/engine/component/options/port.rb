# Network port option.
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
class SCNR::Engine::Component::Options::Port < SCNR::Engine::Component::Options::Base

    def normalize
        effective_value.to_i
    end

    def valid?
        return false if !super
        (1..65535).include?( normalize )
    end

    def type
        :port
    end

end
