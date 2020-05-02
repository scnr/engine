=begin
    Copyright 2020 Tasos Laskos <tasos.laskos@gmail.com>

    This file is part of the SCNR::Engine project and is subject to
    redistribution and commercial restrictions. Please see the SCNR::Engine
    web site for more information on licensing and terms of use.
=end

# Extract paths from HTML comments.
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
class SCNR::Engine::Parser::Extractors::Comments < SCNR::Engine::Parser::Extractors::Base

    def run
        return [] if !check_for?( '<!--' )

        c = []
        document.traverse_comments do |comment|
            c << comment.text.scan( /(^|\s)(\/[\/a-zA-Z0-9%._-]+)/ )
        end
        c.flatten.select { |s| s.start_with? '/' }
    end

end
