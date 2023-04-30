=begin
    Copyright 2020-2022 Tasos Laskos <tasos.laskos@gmail.com>

    This file is part of the SCNR::Engine project and is subject to
    redistribution and commercial restrictions. Please see the SCNR::Engine
    web site for more information on licensing and terms of use.
=end

module SCNR::Engine
module HTTP
class ProxyServer

class Connection < Raktr::Connection
    include SCNR::Engine::UI::Output
    personalize_output!

    class<<self
        include SCNR::Engine::UI::Output
        personalize_output!
    end

    SKIP_HEADERS = %w(transfer-encoding connection proxy-connection keep-alive
        content-encoding te trailers accept-encoding accept-ranges vary
        authorization upgrade http2-settings)

    attr_reader :parent
    attr_reader :request

    def initialize( options = {} )
        @options = options
        @parent  = options[:parent]

        @body     = ''
        @parser   = ::HTTP::Parser.new
        @raw_request = ''

        @parser.on_message_begin = proc do
            if @reused
                print_debug_level_3 "Reusing connection: #{object_id}"
            else
                print_debug_level_3 "Starting new connection: #{object_id}"
            end

            @reused = true

            print_debug_level_3 'Incoming request.'
            @parent.mark_connection_active self
        end

        @parser.on_body = proc do |chunk|
            print_debug_level_3 "Got #{chunk.size} bytes."
            @body << chunk
        end

        @parser.on_message_complete = proc do
            method  = @parser.http_method.downcase.to_sym
            headers = cleanup_request_headers( @parser.headers )

            print_debug_level_3 "Request received: #{@parser.http_method} #{@parser.request_url}"

            if headers['upgrade']
                handle_upgrade( headers )
                next
            end

            if method == :connect
                handle_connect( headers )
                next
            end

            if closed?
                print_debug_level_3 'Connection closed while waiting for' <<
                    " slot: #{@parser.http_method} #{@parser.request_url}"
                next
            end

            handle_request @request = SCNR::Engine::HTTP::Request.new(
                http_opts.merge(
                    url:     sanitize_url( @parser.request_url, headers ),
                    method:  method,
                    body:    @body,
                    mode: :sync,
                    headers: SCNR::Engine::HTTP::Client.headers.to_h.merge( headers ),
                    fingerprint: false,
                    update_cookies: false,
                    do_not_manipulate_cookies: true
                )
            )
        end
    end

    def handle_upgrade( headers )
        print_debug_level_3 'Preparing to upgrade.'

        host = (headers['Host'] || @parser.request_url).split( ':', 2 ).first

        @tunnel = raktr.connect( host, 80, Tunnel, @options.merge( client: self ) )

        # This is our last HTTP message, from this point on we'll only be
        # tunnelling to the origin server.
        @last_http = true
        @tunnel.write @raw_request
    end

    def handle_connect( headers )
        print_debug_level_3 'Preparing to intercept.'

        host = (headers['Host'] || @parser.request_url).split( ':', 2 ).first
        start_interceptor( host )

        # This is our last HTTP message, from this point on we'll only be
        # tunnelling to the interceptor.
        @last_http = true
        write "HTTP/#{http_version} 200\r\n\r\n"
    end

    def handle_request( request )
        print_debug_level_3 'Processing request.'

        if @options[:request_handler]
            print_debug_level_3 "-- Has special handler: #{@options[:request_handler]}"

            # Provisional empty, response in case the request_handler wants us to
            # skip performing the request.
            response = Response.new( url: request.url )
            response.request = request

            # If the handler returns false then don't perform the HTTP request.
            if @options[:request_handler].call( request, response )
                print_debug_level_3 '-- Handler approves, running...'

                @parent.thread_pool.post do
                    self.class.bridge( self, raktr, request )
                end
            else
                print_debug_level_3 '-- Handler did not approve, will not run.'

                if closed?
                    print_debug_level_3 '-- Connection closed, will not respond.'
                    return
                end

                raktr.schedule do
                    handle_response( response )
                    print_debug_level_3 "-- ...completed in #{response.time}: #{response.status_line}"
                    print_debug_level_3 'Processed request.'
                end
            end
        else
            print_debug_level_3 '-- Running...'

            @parent.thread_pool.post do
                self.class.bridge( self, raktr, request )
            end
        end
    end

    def self.bridge( connection, raktr, request )
        response = request.run
        HTTP::Client.global_on_complete response

        if connection.closed?
            print_debug_level_3 '-- Connection closed, will not respond.'
            return
        end

        raktr.schedule do
            connection.handle_response( response )
            print_debug_level_3 "-- ...completed in #{response.time}: #{response.status_line}"
            print_debug_level_3 'Processed request.'
        end
    end

    def http_version
        @parser.http_version.join('.')
    end

    def handle_response( response )
        print_debug_level_3 'Preparing response.'

        # Connection was rudely closed before we had a chance to respond,
        # don't bother proceeding.
        if closed?
            print_debug_level_3 '-- Connection closed, will not respond.'
            return
        end

        if @options[:response_handler]
            print_debug_level_3 "-- Has special handler: #{@options[:response_handler]}"
            @options[:response_handler].call( response.request, response )
        end

        code = response.code
        if response.code == 0
            code = 504
        end

        write "HTTP/#{http_version} #{code}\r\n"

        headers = cleanup_response_headers( response.headers )
        headers['Content-Length'] = response.body.bytesize

        if response.text? && headers.content_type
            headers['Content-Type'] = "#{headers.content_type.split( ';' ).first}"
        end

        headers.each do |k, v|
            if v.is_a?( Array )
                v.flatten.each do |h|
                    write "#{k}: #{h.gsub(/[\n\r]/, '')}\r\n"
                end

                next
            end

            write "#{k}: #{v}\r\n"
        end

        write "\r\n"

        print_debug_level_3 "Sending response for: #{@request.url}"
        write response.body
    end

    def on_close( reason = nil )
        print_debug_level_3 "Closed because: [#{reason.class}] #{reason}"

        @parent.mark_connection_inactive self

        if @ssl_interceptor
            @ssl_interceptor.close( reason )
            @ssl_interceptor = nil
        end

        if @tunnel
            @tunnel.close_without_callback
            @tunnel = nil
        end

        @body.clear
        @raw_request.clear
        @request = nil

        @parser.reset!
    end

    def on_flush
        if !@tunnel || @last_http

            if @last_http
                print_debug_level_3 'Last response sent, switching to tunnel.'
            elsif @request
                print_debug_level_3 "Response sent for: #{@request.url}"
            end

            @last_http = false
        end

        @body.clear
        @raw_request.clear
        @request = nil

        @parser.reset!
        @parent.mark_connection_inactive self
    end

    def write( data )
        return if closed?
        super data
    end

    def on_read( data )
        if @tunnel
            @tunnel.write( data )
            return
        end

        # We need this in case we need to establish a tunnel for an "Upgrade".
        @raw_request << data
        @parser      << data
    rescue ::HTTP::Parser::Error => e
        close e
    end

    def start_interceptor( origin_host )
        @interceptor_port = Utilities.available_port

        print_debug_level_3 "Starting interceptor on port: #{@interceptor_port}"

        @ssl_interceptor = raktr.listen(
          @options[:address], @interceptor_port, SSLInterceptor,
          @options.merge( origin_host: origin_host )
        )

        @tunnel = raktr.connect(
          @options[:address], @interceptor_port, Tunnel,
          @options.merge( client: self )
        )
    end

    def cleanup_request_headers( headers )
        headers = SCNR::Engine::HTTP::Headers.new( headers )

        SKIP_HEADERS.each do |name|
            headers.delete name
        end

        headers.to_h
    end

    def cleanup_response_headers( headers )
        SKIP_HEADERS.each do |name|
            headers.delete name
        end
        headers
    end

    def sanitize_url( str, headers )
        uri = SCNR::Engine::URI( str )
        return uri.to_s if uri.absolute?

        host, port = *headers['Host'].split( ':', 2 )

        uri = uri.dup
        uri.scheme = self.is_a?( SSLInterceptor ) ? 'https' : 'http'
        uri.host = host
        uri.port = port ? port.to_i : nil

        uri.to_s
    end

    # @param    [Hash]  options
    #   Merges the given HTTP options with some default ones.
    def http_opts( options = {} )
        options.merge(
            performer:         self,

            # Don't follow redirects, the client should handle this.
            follow_location:   false,

            # Set the HTTP request timeout.
            timeout:           @options[:timeout],

            # Update the framework-wide cookie-jar with the transmitted cookies.
            update_cookies:    true,

            # We perform the request in blocking mode, parallelism is up to the
            # proxy client.
            mode:              :sync,

            # Don't limit the response size when using the proxy.
            response_max_size: -1
        )
    end
end

end
end
end
