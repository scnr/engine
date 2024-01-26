=begin
    Copyright 2024 Ecsypno Single Member P.C.

    This file is part of the SCNR::Engine project and is subject to
    redistribution and commercial restrictions. Please see the SCNR::Engine
    web site for more information on licensing and terms of use.
=end

module SCNR::Engine
module Platform::Fingerprinters

# Identifies Rack applications.
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
# @version 0.1.2
class Rack < Platform::Fingerprinter

    SESSIONID = 'rack.session'

    def run
        return if !powered_by.include?( 'mod_rack' ) &&
            !headers.keys.find { |h| h.include? 'x-rack' } &&
            !cookies.include?( SESSIONID )

        platforms << :ruby << :rack
    end

end

end
end
