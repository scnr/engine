=begin
    Copyright 2024 Ecsypno Single Member P.C.

    This file is part of the SCNR::Engine project and is subject to
    redistribution and commercial restrictions. Please see the SCNR::Engine
    web site for more information on licensing and terms of use.
=end

module SCNR::Engine
module Platform::Fingerprinters

# Identifies Default Symfony Framework cookie.
#
# @author Tomas Dobrotka <tomas@dobrotka.sk>
# @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
# @version 0.1
class Symfony < Platform::Fingerprinter

    def run
        return if !cookies.include?( 'symfony' )

        platforms << :php << :symfony
    end

end

end
end
