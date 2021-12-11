module SCNR::Engine

lib = Options.paths.lib
require lib + 'component/output'
require lib + 'component/utilities'

module Component

# Base check class to be extended by all components.
#
# Defines basic structure and provides utilities.
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
# @abstract
class Base
    include SCNR::Engine # I hate having to keep typing this all the time.
    include Component::Output

    include Component::Utilities
    extend  Component::Utilities

    def shortname
        self.class.shortname
    end

    def fullname
        self.class.fullname
    end

    class <<self
        include SCNR::Engine::Component::Output

        def fullname
            @fullname ||= info[:name]
        end

        def description
            @description ||= info[:description]
        end

        def author
            @author ||= info[:author]
        end

        def version
            @version ||= info[:version]
        end

        def shortname=( shortname )
            @shortname = shortname
        end

        def shortname
            @shortname
        end
    end

end
end
end
