=begin
    Copyright 2020-2022 Tasos Laskos <tasos.laskos@gmail.com>

    This file is part of the SCNR::Engine project and is subject to
    redistribution and commercial restrictions. Please see the SCNR::Engine
    web site for more information on licensing and terms of use.
=end

module SCNR::Engine
module Platform::Fingerprinters

# Identifies CakePHP resources.
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
#
# @version 0.1
class CakePHP < Platform::Fingerprinter

    def run
        if cookies.include?( 'cakephp' )
            platforms << :php << :cakephp
        end
    end

end

end
end
