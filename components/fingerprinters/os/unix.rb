=begin
    Copyright 2020-2022 Tasos Laskos <tasos.laskos@gmail.com>

    This file is part of the SCNR::Engine project and is subject to
    redistribution and commercial restrictions. Please see the SCNR::Engine
    web site for more information on licensing and terms of use.
=end

module SCNR::Engine
module Platform::Fingerprinters

#
# Identifies *nix operating systems whose flavor couldn't be determines.
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
#
# @version 0.1
#
class Unix < Platform::Fingerprinter

    def run
        platforms << :unix if server_or_powered_by_include? 'unix'
    end

end

end
end
