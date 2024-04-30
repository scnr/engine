=begin
    Copyright 2024 Ecsypno Single Member P.C.

    This file is part of the SCNR::Engine project and is subject to
    redistribution and commercial restrictions. Please see the SCNR::Engine
    web site for more information on licensing and terms of use.
=end

module SCNR::Engine
class Browser
module Parts

module HTTP
    include Support::Mixins::Observable

    # @!method on_response( &block )
    advertise :on_response

    # @return   [Array<HTTP::Request>]
    attr_reader :requests

    attr_reader :window_responses

    AD_HOSTS = Support::Filter::Set.new
    File.open( Options.paths.root + 'config/adservers.txt' ) do |f|
        f.each_line do |entry|
            next if entry.start_with?( '#' )
            AD_HOSTS << entry.split( ' ' ).last
        end
    end

    def self.included( base )
        base.extend( ClassMethods )
    end

    module ClassMethods
        def request_for_ad?( request )
            AD_HOSTS.include?( request.parsed_url.domain )
        end
    end

    def initialize
        super
        @ignore_scope = @options[:ignore_scope]
        @requests = []
    end

    def response
        u = self.dom_url

        if u == 'about:blank'
            print_debug 'Blank page.'
            return
        end

        if skip_path?( u )
            print_debug "Response is out of scope: #{u}"
            return
        end

        t = Time.now
        while !(r = get_response( u ))
            sleep 0.05
            return if Time.now - t > (Options.http.request_timeout / 1_000)
        end

        r
    end

    private

    def request_token
        @request_token ||= generate_token
    end

    def request_handler( request, response )
        # Engine boot-up request, do not allow.
        # Won't concern the scan anyways.
        return if !engine

        if request.url.include? '/data_flow_sink_signal/'
            @has_data_flow_sink_signal = true
            return
        end

        request.performer = self

        print_debug_level_2 "Request: #{request.url}"

        if @add_requests && request.url != @last_url && !@javascript.serve?( request )
            @requests << request.dup
        end

        if !engine.allow_request?( request )
            print_debug_level_2 "Ignoring, blacklisted by engine: #{engine}"
            return
        end

        if self.class.request_for_ad?( request )
            print_debug_level_2 "Ignoring, ad host: #{request.url}"
            return
        end

        # We can't have 304 page responses in the framework, we need full request
        # and response data, the browser cache doesn't help us here.
        #
        # Still, it's a nice feature to have when requesting assets or anything
        # else.
        if !@last_url || request.url == @last_url
            request.headers.delete 'If-None-Match'
            request.headers.delete 'If-Modified-Since'
        end

        if @javascript.serve( request, response )
            print_debug_level_2 'Serving local JS.'
            return
        end

        if request.parsed_url.scope.exclude_path_patterns?
            print_debug_level_2 'Disallow: Matches exclusion rules.'
            return
        end

        # Signal the proxy to not actually perform the request if we have a
        # preloaded response for it.
        if from_preloads( request, response )
            print_debug_level_2 'Resource has been preloaded.'

            # There may be taints or custom JS code that need to be updated.
            javascript.inject response
            return
        end

        print_debug_level_2 'Request can proceed to origin.'

        # Capture the request as elements of pages -- let's us grab AJAX and
        # other browser requests and convert them into elements we can analyze
        # and audit.
        capture_request( request ) if request.scope.in?

        request.headers['user-agent'] = Options.device.user_agent

        # Signal the proxy to continue with its request to the origin server.
        true
    end

    def response_handler( request, response )
        return if request.url.include?( request_token )

        # Prevent browser from caching the root page, we need to have an
        # associated response.
        #
        # Also don't cache when we don't have a @last_url because this could
        # be driven directly from Selenium/Watir via a plugin and caching it
        # can ruin the scan.
        if !@last_url || @last_url == response.url
            response.headers.delete 'Cache-control'
            response.headers.delete 'Etag'
            response.headers.delete 'Date'
            response.headers.delete 'Last-Modified'
        end

        # Allow our own scripts to run.
        response.headers.delete 'Content-Security-Policy'

        print_debug_level_2 "Got response: #{response.url}"

        # If we abort the request because it's out of scope we need to emulate
        # an OK response because we **do** want to be able to grab a page with
        # the out of scope URL, even if it's empty.
        # For example, unvalidated_redirect checks need this.
        if response.code == 0
            if enforce_scope? && response.scope.out?
                response.code = 200
            end
        else
            if (response.scope.in? || response.parsed_url.seed_in_host?) &&
                javascript.inject( response )

                print_debug_level_2 'Injected custom JS.'
            end
        end

        # Don't store assets, the browsers will cache them accordingly.
        if !response.text?
            print_debug_level_2 'Asset detected....'
            return
        end

        # No-matter the scope, don't store resources for external domains.
        if !response.scope.in_domain?
            print_debug_level_2 'Outside of domain scope...'
            return
        end

        if enforce_scope? && response.scope.out?
            print_debug_level_2 'Outside of general scope...'
            return
        end

        save_response response

        print_debug_level_2 'Stored.'

        nil
    end

    def from_preloads( request, response )
        return if !(preloaded = preloads.delete( request.url ))

        copy_response_data( preloaded, response )
        response.request = request
        save_response( response ) if !preloaded.url.include?( request_token )

        preloaded
    end

    def copy_response_data( source, destination )
        [:code, :url, :body, :headers, :ip_address, :return_code,
         :return_message, :headers_string, :total_time, :time].each do |m|
            destination.send "#{m}=", source.send( m )
        end

        javascript.inject destination
        nil
    end

    def save_response( response )
        notify_on_response response
        return response if !response.text?

        @window_responses[make_response_key( response.url )] = response
    end

    def get_response( url )
        @window_responses[make_response_key( url )]
    end

    def make_response_key( url )
        # Normalize by decoding components and putting params in order.
        uri = SCNR::Engine::URI.parse( url )
        [
            uri.scheme, uri.host, uri.port, SCNR::Engine::URI.decode( uri.path ),
            uri.query_parameters.
              map { |k, v| [SCNR::Engine::URI.decode( k ), SCNR::Engine::URI.decode( v )] }.
              sort_by { |k, _| k }.hash
        ].hash
    end

    def enforce_scope?
        !@ignore_scope
    end

end

end
end
end
