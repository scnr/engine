=begin
    Copyright 2024 Ecsypno Single Member P.C.

    This file is part of the SCNR::Engine project and is subject to
    redistribution and commercial restrictions. Please see the SCNR::Engine
    web site for more information on licensing and terms of use.
=end

# Extracts paths from `script` HTML elements.
# Both from `src` and the text inside the scripts.
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
class SCNR::Engine::Parser::Extractors::Scripts < SCNR::Engine::Parser::Extractors::Base

    def run
        return [] if !check_for?( 'script' )

        u = []
        document.nodes_by_name( 'script' ) do |s|
            u << ([s['src']].flatten.compact | from_text( s.text ))
        end
        u.flatten
    end

    def from_text( text )
        return [] if !text

        text.scan( /[\/a-zA-Z0-9%._-]+/ ).
            select do |s|
            # String looks like a path, but don't get fooled by comments.
            s.include?( '.' ) && s.include?( '/' )  &&
                !s.include?( '*' ) && !s.start_with?( '//' ) &&

                # Require absolute paths, otherwise we may get caught in
                # a loop, this context isn't the most reliable for extracting
                # real paths.
                s.start_with?( '/' )
        end
    end

end
