=begin
    Copyright 2020 Tasos Laskos <tasos.laskos@gmail.com>

    This file is part of the SCNR::Engine project and is subject to
    redistribution and commercial restrictions. Please see the SCNR::Engine
    web site for more information on licensing and terms of use.
=end

module SCNR
module Engine

    URI = if Engine.has_extension?
                require Engine::Options.paths.lib + 'uri_ext'
                Engine::URIExt
            else
                require Engine::Options.paths.lib + 'uri_ruby'
                Engine::URIRuby
            end

    def self.URI( uri )
        Engine::URI.parse(uri )
    end
end
end
