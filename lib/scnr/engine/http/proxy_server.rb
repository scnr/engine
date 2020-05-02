=begin
    Copyright 2020 Alex Douckas <alexdouckas@gmail.com>, Tasos Laskos <tasos.laskos@gmail.com>

    This file is part of the SCNR::Engine project and is subject to
    redistribution and commercial restrictions. Please see the SCNR::Engine
    web site for more information on licensing and terms of use.
=end

require 'http/parser'
require 'arachni/reactor'

require_relative 'proxy_server/tunnel'
require_relative 'proxy_server/connection'
require_relative 'proxy_server/ssl_interceptor'

module SCNR::Engine
module HTTP

# @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
class ProxyServer
    include SCNR::Engine::UI::Output
    personalize_output!

    # Higher concurrency means more Threads, more Threads means more RAM.
    DEFAULT_CONCURRENCY = 2

    # @param   [Hash]  options
    # @option options   [String]    :address    ('0.0.0.0')
    #   Address to bind to.
    # @option options   [Integer]    :port
    #   Port number to listen on -- defaults to a random port.
    # @option options   [Integer]    :timeout
    #   HTTP time-out for each request in milliseconds.
    # @option options   [Integer]    :concurrency   (DEFAULT_CONCURRENCY)
    #   Amount of origin requests to be active at any given time.
    # @option options   [Block]    :response_handler
    #   Block to be called to handle each response as it arrives -- will be
    #   passed the request and response.
    # @option options   [Block]    :request_handler
    #   Block to be called to handle each request as it arrives -- will be
    #   passed the request and response.
    def initialize( options = {} )
        @reactor = Arachni::Reactor.new(
            # Higher than the defaults to keep object allocations down.
            select_timeout:    0.1,
            max_tick_interval: 0.1
        )
        @options = options

        @active_connections = Concurrent::Map.new

        @options[:concurrency] ||= DEFAULT_CONCURRENCY
        @options[:address]     ||= '127.0.0.1'
        @options[:port]        ||= Utilities.available_port

        @concurrency_control_tokens = @reactor.create_queue
    end

    # Starts the server without blocking, it'll only block until the server is
    # up and running and ready to accept connections.
    def start_async
        print_debug_level_2 'Starting...'

        @reactor.run_in_thread

        @thread_pool = Concurrent::FixedThreadPool.new( @options[:concurrency] )

        @options[:concurrency].times do |i|
            @concurrency_control_tokens << i
        end

        @reactor.on_error do |_, e|
            print_exception e
        end

        @reactor.listen(
            @options[:address], @options[:port], Connection,
            @options.merge( parent: self )
        )

        print_debug_level_2 "...started at: #{url}"
        nil
    end

    def shutdown
        print_debug_level_2 'Shutting down...'

        @thread_pool.kill if @thread_pool
        @thread_pool = nil

        @reactor.stop
        @reactor.wait

        print_debug_level_2 '...shutdown.'
    end

    # @return   [Bool]
    #   `true` if the server is running, `false` otherwise.
    def running?
        @reactor.running?
    end

    # @return   [String]
    #   Proxy server URL.
    def url
        "http://#{@options[:address]}:#{@options[:port]}"
    end

    def on_available_slot( connection, &block )
        if !@thread_pool
            print_debug 'Trying to get slot after shutdown, ignoring.'
            return
        end

        if !has_available_request_tokens?
            connection.print_debug_level_3 'Waiting for a request token.'
        end

        # We do it this way in order to control concurrency limits asynchronously,
        # via the Reactor, rather than block, via the ThreadPool.
        get_request_token do |token|
            connection.print_debug_level_3 "Got request token ##{token}."

            if connection.closed?
                connection.print_debug_level_3 'Closed while waiting for a request token.'
                return_request_token( token )
                connection.print_debug_level_3 "Returned request token ##{token}."

                next
            end

            if !@thread_pool
                connection.print_debug 'Got slot after proxy shutdown, ignoring.'
                return_request_token( token )
                connection.print_debug_level_3 "Returned request token ##{token}."

                next
            end

            @thread_pool.post do
                begin
                    block.call
                rescue => e
                    print_exception e
                    connection.close e
                ensure
                    return_request_token( token )
                    return_request_token.print_debug_level_3 "Returned request token ##{token}."
                end
            end
        end

    end

    # @return   [Bool]
    #   `true` if the proxy has pending requests, `false` otherwise.
    def has_pending_requests?
        pending_requests != 0
    end

    # @return   [Integer]
    #   Amount of active requests.
    def pending_requests
        @active_connections.size
    end

    def active_connections
        @active_connections.keys
    end

    def mark_connection_active( connection )
        @active_connections.put_if_absent( connection, nil )
    end

    def mark_connection_inactive( connection )
        @active_connections.delete connection
    end

    private

    def get_request_token( &block )
        @concurrency_control_tokens.pop( &block )
    end

    def return_request_token( token )
        @concurrency_control_tokens << token
    end

    def has_available_request_tokens?
        @concurrency_control_tokens.empty?
    end

end

end
end
