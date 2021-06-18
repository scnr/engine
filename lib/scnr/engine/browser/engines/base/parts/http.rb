=begin
    Copyright 2020 Alex Douckas <alexdouckas@gmail.com>, Tasos Laskos <tasos.laskos@gmail.com>

    This file is part of the SCNR::Engine project and is subject to
    redistribution and commercial restrictions. Please see the SCNR::Engine
    web site for more information on licensing and terms of use.
=end

module SCNR::Engine
class Browser
class Engines
class Base
module Parts

module HTTP

    def allow_request?( request )
        !request_blacklist.find { |rule| rule.match?( request.url ) }
    end

    def wait_for_pending_requests
        t                = Time.now
        last_connections = []

        while proxy.has_pending_requests?
            connections = proxy.active_connections

            if last_connections != connections
                print_debug_level_2 "Waiting for #{proxy.pending_requests} requests to complete:"

                connections.each do |connection|
                    if connection.request
                        print_debug_level_2 " * #{connection.request.url}"
                    else
                        print_debug_level_2 ' * Still reading request data.'
                    end
                end

            end

            last_connections = connections

            sleep 0.05

            # If the browser sends incomplete data the connection will remain
            # open indefinitely.
            next if Time.now - t < Options.dom.job_timeout

            connections.each(&:close)
            break
        end
    end

    private

    # @abstract
    def request_blacklist
        []
    end

    def proxy
        return @proxy if @proxy

        print_debug 'Booting up proxy...'

        print_debug_level_2 'Starting proxy...'
        @proxy = SCNR::Engine::HTTP::ProxyServer.new(
            concurrency:      @options[:concurrency],
            address:          '127.0.0.1',
            request_handler:  proc do |request, response|
                Utilities.exception_jail { request_handler( request, response ) }
            end,
            response_handler: @options[:response_handler]
        )
        @proxy.start_async
        print_debug_level_2 "... started proxy at: #{@proxy.url}"

        @proxy
    end

    def request_handler( request, response )
        if !allow_request?( request )
            print_debug_level_2 "Request: #{request.url}"
            print_debug_level_2 "Ignoring, blacklisted by engine: #{name}"
            return
        end

        @options[:request_handler].call( request, response )
    end

end

end
end
end
end
end
