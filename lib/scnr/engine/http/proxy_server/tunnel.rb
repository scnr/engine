=begin
    Copyright 2020-2022 Tasos Laskos <tasos.laskos@gmail.com>

    This file is part of the SCNR::Engine project and is subject to
    redistribution and commercial restrictions. Please see the SCNR::Engine
    web site for more information on licensing and terms of use.
=end

module SCNR::Engine
module HTTP
class ProxyServer

# @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
class Tunnel < Raktr::Connection
    include SCNR::Engine::UI::Output
    personalize_output!

    def initialize( options )
        print_debug_level_3 'New tunnel.'

        @client = options[:client]
    end

    def on_connect
        print_debug_level_3 'Connected.'
    end

    def write( data )
        print_debug_level_3 " -> Forwarding #{data.size} bytes."
        super data
    end

    def on_close( reason = nil )
        print_debug_level_3 "Closed because: [#{reason.class}] #{reason}"

        # ap self.class
        # ap 'CLOSE'
        # ap reason

        @client.close reason
    end

    def on_read( data )
        # ap self.class
        # ap 'READ'
        # ap data
        print_debug_level_3 "<- Forwarding #{data.size} bytes to client."
        @client.write data
    end
end

end
end
end
