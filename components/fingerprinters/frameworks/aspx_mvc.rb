=begin
    Copyright 2020 Tasos Laskos <tasos.laskos@gmail.com> 

    This file is part of the SCNR::Engine project and is subject to
    redistribution and commercial restrictions. Please see the SCNR::Engine
    web site for more information on licensing and terms of use.
=end

module SCNR::Engine
module Platform::Fingerprinters

# Identifies ASP.NET MVC resources.
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
# @version 0.1
class ASPXMVC < Platform::Fingerprinter

    ANTI_CSRF_NONCE = '__requestverificationtoken'
    HEADER_FIELDS   = %w(x-aspnetmvc-version)

    def run
        # Naive but enough, I think.
        if html? && page.body =~ /input.*#{ANTI_CSRF_NONCE}/i
            return update_platforms
        end

        if (headers.keys & HEADER_FIELDS).any?
            return update_platforms
        end

        if cookies.include?( ANTI_CSRF_NONCE )
            update_platforms
        end
    end

    def update_platforms
        platforms << :asp << :aspx << :windows << :aspx_mvc
    end

end

end
end
