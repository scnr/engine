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

module Queue

    def self.registered( app )

        app.get '/queue' do
            ensure_queue!

            handle_error do
                json queue.list
            end
        end

        app.get '/queue/url' do
            ensure_queue!

            handle_error do
                json Options.queue.url
            end
        end

        app.put '/queue/url' do
            url = ::JSON.load( request.body.read ) || {}

            handle_error do
                connect_to_queue( url ).alive?

                @queue = nil
                Options.queue.url = url
                json nil
            end
        end

        app.delete '/queue/url' do
            ensure_queue!

            json @queue = Options.queue.url = nil
        end

        app.get '/queue/running' do
            ensure_queue!

            handle_error do
                json queue.running
            end
        end

        app.get '/queue/completed' do
            ensure_queue!

            handle_error do
                json queue.completed
            end
        end

        app.get '/queue/failed' do
            ensure_queue!

            handle_error do
                json queue.failed
            end
        end

        app.get '/queue/size' do
            ensure_queue!

            handle_error do
                json queue.size
            end
        end

        app.delete '/queue' do
            ensure_queue!

            handle_error do
                json queue.clear
            end
        end

        app.post '/queue' do
            ensure_queue!

            handle_error do
                json id: queue.push( ::JSON.load( request.body.read ) || {} )
            end
        end

        app.get '/queue/:scan' do |scan|
            ensure_queue!

            handle_error do
                scan = queue.get( scan )
                if !scan
                    halt 404, json( 'Scan not in Queue.' )
                end

                json scan
            end
        end

        app.put '/queue/:scan/detach' do |scan|
            ensure_queue!

            handle_error do
                info = queue.detach( scan )

                if !info
                    halt 404, json( 'Scan not in Queue.' )
                end

                instances[scan] ||= connect_to_instance( info['url'], info['token'] )
            end

            json nil
        end

        app.delete '/queue/:scan' do |scan|
            ensure_queue!

            handle_error do
                if queue.remove( scan )
                    json nil
                else
                    halt 404, json( 'Scan not in Queue.' )
                end
            end
        end

    end

end

end
end
end
end
