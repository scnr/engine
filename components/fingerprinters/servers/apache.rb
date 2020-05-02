=begin
    Copyright 2020 Tasos Laskos <tasos.laskos@gmail.com> 

    This file is part of the SCNR::Engine project and is subject to
    redistribution and commercial restrictions. Please see the SCNR::Engine
    web site for more information on licensing and terms of use.
=end

module SCNR::Engine
module Platform::Fingerprinters

# Identifies Apache web servers.
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
# @version 0.1
class Apache < Platform::Fingerprinter

    def run
        if server_or_powered_by_include?( 'apache' ) &&
            !server_or_powered_by_include?( 'coyote' )

            platforms << :apache
        end
    end

end

end
end
