=begin
    Copyright 2020 Alex Douckas <alexdouckas@gmail.com>, Tasos Laskos <tasos.laskos@gmail.com> 

    This file is part of the SCNR::Engine project and is subject to
    redistribution and commercial restrictions. Please see the SCNR::Engine
    web site for more information on licensing and terms of use.
=end

module SCNR::Engine
module Rest
class Server

module InstanceHelpers

    @@instances   = {}
    @@dispatchers = {}

    def get_instance
        if dispatcher
            args = [
                'rest',
                {
                    owner: {
                        url: env['HTTP_HOST']
                    }
                }
            ]

            if (info = dispatcher.dispatch( *args ))
                connect_to_instance( info['url'], info['token'] )
            end
        else
            Processes::Instances.spawn( fork: false )
        end
    end

    def dispatchers
        @@dispatchers.keys
    end

    def dispatcher
        return if !Options.dispatcher.url
        @dispatcher ||= connect_to_dispatcher( Options.dispatcher.url )
    end

    def unplug_dispatcher( url )
        connect_to_dispatcher( url ).node.unplug

        c = @@dispatchers.delete( url )
        c.close if c
    end

    def connect_to_dispatcher( url )
        @@dispatchers[url] ||= RPC::Client::Dispatcher.new( url )
    end

    def connect_to_instance( url, token )
        RPC::Client::Instance.new( url, token )
    end

    def update_from_queue
        return if !queue

        queue.running.each do |id, info|
            instances[id] ||= connect_to_instance( info['url'], info['token'] )
        end

        (queue.failed.keys | queue.completed.keys).each do |id|
            session.delete id
            client = instances.delete( id )
            client.close if client
        end
    end

    def queue
        return if !Options.queue.url
        @queue ||= connect_to_queue( Options.queue.url )
    end

    def connect_to_queue( url )
        RPC::Client::Queue.new( url )
    end

    def instances
        @@instances
    end

    def instance_for( id, &block )
        cleanup = proc do
            instances.delete( id ).close
            session.delete id
        end

        handle_error cleanup do
            block.call @@instances[id]
        end
    end

    def exists?( id )
        instances.include? id
    end

end

end
end
end
