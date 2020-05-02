=begin
    Copyright 2020 Alex Douckas <alexdouckas@gmail.com>, Tasos Laskos <tasos.laskos@gmail.com>

    This file is part of the SCNR::Engine project and is subject to
    redistribution and commercial restrictions. Please see the SCNR::Engine
    web site for more information on licensing and terms of use.
=end

module SCNR::Engine
module Platform::Fingerprinters

# Identifies Ruby resources.
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
#
# @version 0.1
class Ruby < Platform::Fingerprinter

    IDs = %w(mod_rack phusion passenger)

    def run
        IDs.each do |id|
            next if !powered_by.include? id
            return platforms << :ruby << :rack
        end
    end

end

end
end
