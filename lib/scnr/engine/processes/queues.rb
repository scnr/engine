=begin
    Copyright 2020 Tasos Laskos <tasos.laskos@gmail.com>

    This file is part of the SCNR::Engine project and is subject to
    redistribution and commercial restrictions. Please see the SCNR::Engine
    web site for more information on licensing and terms of use.
=end

module SCNR::Engine
module Processes

# Helper for managing {RPC::Server::Queue} processes.
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
class Queues
    include Singleton
    include Utilities

    # @return   [Array<String>] URLs of all running Queues.
    attr_reader :list

    def initialize
        @list    = []
        @clients = {}
    end

    # Connects to a Queue by URL.
    #
    # @param    [String]    url URL of the Queue.
    # @param    [Hash]    options Options for the RPC client.
    #
    # @return   [RPC::Client::Queue]
    def connect( url, options = nil )
        Arachni::Reactor.global.run_in_thread if !Arachni::Reactor.global.running?

        fresh = false
        if options
            fresh = options.delete( :fresh )
        end

        if fresh
            @clients[url] = RPC::Client::Queue.new( url, options )
        else
            @clients[url] ||= RPC::Client::Queue.new( url, options )
        end
    end

    # @param    [Block] block   Block to pass an RPC client for each Queue.
    def each( &block )
        @list.each do |url|
            block.call connect( url )
        end
    end

    # Spawns a {RPC::Server::Queue} process.
    #
    # @param    [Hash]  options
    #   To be passed to {SCNR::Engine::Options#set}. Allows `address` instead of
    #   `rpc_server_address` and `port` instead of `rpc_port`.
    #
    # @return   [RPC::Client::Queue]
    def spawn( options = {} )
        fork = options.delete(:fork)

        options = {
            dispatcher: {
                url: options[:dispatcher],
            },
            rpc:        {
                server_port:             options[:port]    || Utilities.available_port,
                server_address:          options[:address] || '127.0.0.1',
                server_external_address: options[:external_address]
            }
        }

        pid = Manager.spawn( :queue, options: options, fork: fork )

        url = "#{options[:rpc][:server_address]}:#{options[:rpc][:server_port]}"
        while sleep( 0.1 )
            begin
                connect( url, connection_pool_size: 1, max_retries: 1 ).alive?
                break
            rescue => e
                # ap e
            end
        end

        @list << url
        connect( url, fresh: true ).tap { |c| c.pid = pid }
    end

    # @note Will also kill all Instances started by the Queue.
    #
    # @param    [String]    url URL of the Queue to kill.
    def kill( url )
        queue = connect( url )
        queue.clear
        queue.running.each do |id, instance|
            Manager.kill instance['pid']
        end
        Manager.kill queue.pid
    rescue => e
        #ap e
        #ap e.backtrace
        nil
    ensure
        @list.delete( url )
        @clients.delete( url ).close
    end

    # Kills all {Queues #list}.
    def killall
        @list.dup.each do |url|
            kill url
        end
    end

    def self.method_missing( sym, *args, &block )
        if instance.respond_to?( sym )
            instance.send( sym, *args, &block )
        else
            super( sym, *args, &block )
        end
    end

    def self.respond_to?( m )
        super( m ) || instance.respond_to?( m )
    end

end

end
end
