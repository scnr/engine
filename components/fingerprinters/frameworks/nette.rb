=begin
    Copyright 2024 Ecsypno Single Member P.C.

    This file is part of the SCNR::Engine project and is subject to
    redistribution and commercial restrictions. Please see the SCNR::Engine
    web site for more information on licensing and terms of use.
=end

module SCNR::Engine
module Platform::Fingerprinters

# Identifies Nette Framework cookies.
#
# @author Tomas Dobrotka <tomas@dobrotka.sk>
# @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
# @version 0.1
class Nette < Platform::Fingerprinter

    def run
        return if !server_or_powered_by_include?( 'Nette' ) &&
            !cookies.include?( 'nette-browser' )

        platforms << :php << :nette
    end

end

end
end
