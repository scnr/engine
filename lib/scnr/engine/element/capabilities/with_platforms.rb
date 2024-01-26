=begin
    Copyright 2024 Ecsypno Single Member P.C.

    This file is part of the SCNR::Engine project and is subject to
    redistribution and commercial restrictions. Please see the SCNR::Engine
    web site for more information on licensing and terms of use.
=end

module SCNR::Engine
module Element::Capabilities

# @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
module WithPlatforms

    # @return   [Platform]
    #   Applicable platforms for the {Submittable#action} resource.
    def platforms
        Platform::Manager[@action]
    end

end

end
end
