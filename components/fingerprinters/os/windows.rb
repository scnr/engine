=begin
    Copyright 2024 Ecsypno Single Member P.C.

    This file is part of the SCNR::Engine project and is subject to
    redistribution and commercial restrictions. Please see the SCNR::Engine
    web site for more information on licensing and terms of use.
=end

module SCNR::Engine
module Platform::Fingerprinters

#
# Identifies Windows operating systems.
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
#
# @version 0.1
#
class Windows < Platform::Fingerprinter

    IDs = %w(windows win32)

    def run
        IDs.each do |id|
            next if !server_or_powered_by_include? id
            return platforms << :windows
        end
    end

end

end
end
