# Mult-byte character string option.
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
class SCNR::Engine::Component::Options::String < SCNR::Engine::Component::Options::Base

    def normalize
        effective_value.to_s
    end

    def type
        :string
    end

end
