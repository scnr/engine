# Integer option.
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
class SCNR::Engine::Component::Options::Int < SCNR::Engine::Component::Options::Base

    def normalize
        effective_value.to_i
    end

    def valid?
        return false if !super
        /^\d+$/.match? effective_value.to_s
    end

    def type
        :integer
    end

end
