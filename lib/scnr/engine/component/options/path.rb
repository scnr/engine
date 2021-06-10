# Network address option.
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
class SCNR::Engine::Component::Options::Path < SCNR::Engine::Component::Options::Base

    def valid?
        return false if !super
        File.exists?( effective_value )
    end

    def type
        :path
    end

end
