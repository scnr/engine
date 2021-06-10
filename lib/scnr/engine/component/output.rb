module SCNR::Engine
module Component

# Provides output functionality to the checks via {SCNR::Engine::UI::Output},
# prefixing the check name to the output message.
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
module Output
    include UI::Output

    def depersonalize_output
        @depersonalize_output = true
    end

    def depersonalize_output?
        @depersonalize_output
    end

    def personalize_output( message )
        if self.class == Class
            fullname = self.fullname
        else
            fullname = self.class.fullname
        end

        depersonalize_output? ? message : "#{fullname}: #{message}"
    end

end
end
end
