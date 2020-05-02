=begin
    Copyright 2020 Tasos Laskos <tasos.laskos@gmail.com>

    This file is part of the SCNR::Engine project and is subject to
    redistribution and commercial restrictions. Please see the SCNR::Engine
    web site for more information on licensing and terms of use.
=end

module SCNR::Engine
class Browser
class Javascript

# Provides access to the `Events` JS interface.
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
class Events < Proxy

    # @param    [Javascript]    javascript
    #   Active {Javascript} interface.
    def initialize( javascript )
        super javascript, 'Events'
    end

end
end
end
end
