# Floating point option.
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
class SCNR::Engine::Component::Options::Float < SCNR::Engine::Component::Options::Base

    def normalize
        Float( effective_value ) rescue nil
    end

    def valid?
        super && normalize
    end

    def type
        :float
    end

end
