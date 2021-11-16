=begin
    Copyright 2020 Tasos Laskos <tasos.laskos@gmail.com>

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
        @reactor = Arachni::Reactor.new
        @options = options

        @active_connections = ::Set.new

        @options[:address]     ||= '127.0.0.1'
        @options[:port]        ||= Utilities.available_port
    end

    def thread_pool
        @thread_pool ||= Concurrent::ThreadPoolExecutor.new(
            min_threads:     0,
            max_threads:     10,
            max_queue:       10,
            fallback_policy: :caller_runs
        )
    end

    # Starts the server without blocking, it'll only block until the server is
    # up and running and ready to accept connections.
    def start_async
        print_debug_level_2 'Starting...'

        @reactor.run_in_thread

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

        begin
            @reactor.stop
            @reactor.wait
        rescue Arachni::Reactor::Error::NotRunning
        end

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
        @active_connections
    end

    def mark_connection_active( connection )
        @active_connections << connection
    end

    def mark_connection_inactive( connection )
        @active_connections.delete connection
    end

end

end
end
