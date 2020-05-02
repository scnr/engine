=begin
    Copyright 2020 Tasos Laskos <tasos.laskos@gmail.com>

    This file is part of the SCNR::Engine project and is subject to
    redistribution and commercial restrictions. Please see the SCNR::Engine
    web site for more information on licensing and terms of use.
=end

module SCNR::Engine
module Rest
class Server
module Routes

module Grid

    def self.registered( app )

        app.get '/grid' do
            ensure_dispatcher!

            handle_error do
                json [Options.dispatcher.url] + dispatcher.statistics['node']['neighbours']
            end
        end

        app.get '/grid/:dispatcher' do |url|
            ensure_dispatcher!

            handle_error { json connect_to_dispatcher( url ).statistics }
        end

        app.delete '/grid/:dispatcher' do |url|
            ensure_dispatcher!

            handle_error do
                unplug_dispatcher( url )
            end

            json nil
        end

    end

end

end
end
end
end
