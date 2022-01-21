=begin
    Copyright 2020-2022 Tasos Laskos <tasos.laskos@gmail.com>

    This file is part of the SCNR::Engine project and is subject to
    redistribution and commercial restrictions. Please see the SCNR::Engine
    web site for more information on licensing and terms of use.
=end

module SCNR::Engine
module Platform::Fingerprinters

#
# Identifies ASP resources.
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
#
# @version 0.1
#
class ASP < Platform::Fingerprinter

    EXTENSION = 'asp'
    SESSIONID = 'aspsessionid'

    def run
        return if extension != EXTENSION && !parameters.include?( SESSIONID ) &&
            !cookies.include?( SESSIONID ) && !server_or_powered_by_include?( 'asp' )

        platforms << :asp << :windows
    end

end

end
end
