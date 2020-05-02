=begin
    Copyright 2020 Alex Douckas <alexdouckas@gmail.com>, Tasos Laskos <tasos.laskos@gmail.com>

    This file is part of the SCNR::Engine project and is subject to
    redistribution and commercial restrictions. Please see the SCNR::Engine
    web site for more information on licensing and terms of use.
=end

module SCNR::Engine
module Rest
class Server
module Routes

module Dispatcher

    def self.registered( app )

        app.get '/dispatcher/url' do
            ensure_dispatcher!

            json Options.dispatcher.url
        end

        app.put '/dispatcher/url' do
            url = ::JSON.load( request.body.read ) || {}

            handle_error do
                connect_to_dispatcher( url ).alive?

                @dispatcher = nil
                Options.dispatcher.url = url
                json nil
            end
        end

        app.delete '/dispatcher/url' do
            ensure_dispatcher!

            json @dispatcher = Options.dispatcher.url = nil
        end

    end

end

end
end
end
end
