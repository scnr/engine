=begin
    Copyright 2024 Ecsypno Single Member P.C.

    This file is part of the SCNR::Engine project and is subject to
    redistribution and commercial restrictions. Please see the SCNR::Engine
    web site for more information on licensing and terms of use.
=end

module SCNR::Engine
module Platform::Fingerprinters

# Identifies JSF resources.
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
#
# @version 0.1
class JSF < Platform::Fingerprinter

    def run
        if server_or_powered_by_include?( 'jsf' ) ||
            parameters.include?( 'javax.faces.token')

            platforms << :java << :jsf
        end
    end

end

end
end
