=begin
    Copyright 2020 Alex Douckas <alexdouckas@gmail.com>, Tasos Laskos <tasos.laskos@gmail.com>

    This file is part of the SCNR::Engine project and is subject to
    redistribution and commercial restrictions. Please see the SCNR::Engine
    web site for more information on licensing and terms of use.
=end

module SCNR::Engine
module Platform::Fingerprinters

# Identifies Rails resources.
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
# @version 0.1.1
class Rails < Platform::Fingerprinter

    IDs = %w(rails)

    def run
        headers.keys.each do |header|
            return update_platforms if header.start_with?( 'x-rails' )
        end

        IDs.each do |id|
            next if !server_or_powered_by_include? id

            return update_platforms
        end

        if cookies.include?( '_rails_admin_session' )
            update_platforms
        end
    end

    def update_platforms
        platforms << :ruby << :rack << :rails
    end

end

end
end
