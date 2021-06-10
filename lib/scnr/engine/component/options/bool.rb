# Boolean option.
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
class SCNR::Engine::Component::Options::Bool < SCNR::Engine::Component::Options::Base

    TRUE_REGEX   = /^(y|yes|t|1|true|on)$/i
    VALID_REGEXP = /^(y|yes|n|no|t|f|0|1|true|false|on)$/i

    def valid?
        return false if !super
        VALID_REGEXP.match? effective_value.to_s
    end

    def normalize
        TRUE_REGEX.match? effective_value.to_s
    end

    def true?
        normalize
    end

    def false?
        !true?
    end

    def type
        :bool
    end

end
