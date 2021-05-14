=begin
    Copyright 2020 Tasos Laskos <tasos.laskos@gmail.com>

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

    ASSET_EXTENSIONS = Set.new(%w( css js json ))

    ASSET_EXTRACTORS = [
        /<\s*link.*?href=\s*['"]?(.*?)?['"]?[\s>]/im,
        /src\s*=\s*['"]?(.*?)?['"]?[\s>]/i,
    ]

    def self.included( base )
        base.extend( ClassMethods )
        base.asset_domains
    end

    module ClassMethods

        def asset_domains
            @asset_domains ||= Set.new
        end

        def add_asset_domain( url )
            return if url.to_s.empty?
            return if !(curl = SCNR::Engine::URI( url ))
            return if !(domain = curl.domain)

            asset_domains << domain
            domain
        end

    end

    def initialize
        super

        @ignore_scope = @options[:ignore_scope]

        # Captures HTTP::Response objects per URL for open windows.
        @window_responses = {}
    end

    def response
        u = dom_url

        if u == 'about:blank'
            print_debug 'Blank page.'
            return
        end

        if skip_path?( u )
            print_debug "Response is out of scope: #{u}"
            return
        end

        r = get_response( u )

        return r if r && r.code != 504

        if r
            print_debug "Origin server timed-out when requesting: #{u}"
        else
            print_debug "Response never arrived for: #{u}"

            print_debug 'Available responses are:'
            @window_responses.each do |k, _|
                print_debug "-- #{k}"
            end

            print_debug 'Tried:'
            print_debug "-- #{u}"
            print_debug "-- #{normalize_url( u )}"
            print_debug "-- #{normalize_watir_url( u )}"
        end

        nil
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

        if !engine.allow_request?( request )
            print_debug_level_2 "Ignoring, blacklisted by engine: #{engine}"
            return
        end

        if request_for_ad?( request )
            ap '----------------------------------'
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

        if !request.url.include?( request_token )
            if ignore_request?( request )
                print_debug_level_2 'Out of scope, ignoring.'
                return
            end

            if @add_request_transitions
                @request_transitions << Page::DOM::Transition.new(
                    request.url, :request
                )
            end
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

        @request_transitions.each do |transition|
            next if !transition.running? || transition.element != request.url
            transition.complete
        end

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
        if request_for_asset?( request ) || !response.text?
            print_debug_level_2 'Asset detected, will not store.'
            return
        end

        # No-matter the scope, don't store resources for external domains.
        if !response.scope.in_domain?
            print_debug_level_2 'Outside of domain scope, will not store.'
            return
        end

        if enforce_scope? && response.scope.out?
            print_debug_level_2 'Outside of general scope, will not store.'
            return
        end

        whitelist_asset_domains( response )
        save_response response

        print_debug_level_2 'Stored.'

        nil
    end

    def ignore_request?( request )
        print_debug_level_2 "Checking: #{request.url}"

        if !enforce_scope?
            print_debug_level_2 'Allow: Scope enforcement disabled.'
            return
        end

        if request_for_asset?( request )
            print_debug_level_2 'Allow: Asset detected.'
            return false
        end

        if request.scope.exclude_file_extension?
            print_debug_level_2 'Disallow: Cannot follow extension.'
            return true
        end

        if !request.scope.follow_protocol?
            print_debug_level_2 'Disallow: Cannot follow protocol.'
            return true
        end

        if !request.scope.in_domain?
            if self.class.asset_domains.include?( request.parsed_url.domain )
                print_debug_level_2 'Allow: Out of scope but in CDN list.'
                return false
            end

            print_debug_level_2 'Disallow: Domain out of scope and not in CDN list.'
            return true
        end

        if request.scope.too_deep?
            print_debug_level_2 'Disallow: Too deep.'
            return true
        end

        if !request.scope.include?
            print_debug_level_2 'Disallow: Does not match inclusion rules.'
            return true
        end

        if request.scope.exclude?
            print_debug_level_2 'Disallow: Matches exclusion rules.'
            return true
        end

        if request.scope.redundant?
            print_debug_level_2 'Disallow: Matches redundant rules.'
            return true
        end

        false
    end

    def request_for_asset?( request )
        ASSET_EXTENSIONS.include?( request.parsed_url.resource_extension.to_s.downcase )
    end

    def request_for_ad?( request )
        @ad_hosts ||= Support::Filter::Set.new

        if @ad_hosts.empty?
            File.open( Options.paths.root + 'config/adservers.txt' ) do |f|
                f.each_line do |entry|
                    next if entry.start_with?( '#' )
                    @ad_hosts << entry.split( ' ' ).last
                end
            end
        end

        @ad_hosts.include?( request.parsed_url.domain )
    end

    def whitelist_asset_domains( response )
        @whitelist_asset_domains ||= Support::Filter::Set.new
        return if @whitelist_asset_domains.include? response.body
        @whitelist_asset_domains << response.body

        ASSET_EXTRACTORS.each do |regexp|
            response.body.scan( regexp ).flatten.compact.each do |url|
                next if !(domain = self.class.add_asset_domain( url ))

                print_debug_level_2 "#{domain} from #{url} based on #{regexp.source}"
            end
        end
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

        @window_responses[response.url] = response
    end

    def get_response( url )
        # Order is important, #normalize_url by can get confused and remove
        # everything after ';' by treating it as a path parameter.
        # Rightly so...but we need to bypass it when auditing LinkTemplate
        # elements.
        @window_responses[url] ||
            @window_responses[normalize_watir_url( url )] ||
            @window_responses[normalize_url( url )]
    end

    def normalize_watir_url( url )
        normalize_url( encode_semicolon( url ) ).gsub( '%3B', '%253B' )
    end

    def encode_semicolon( str )
        if SCNR::Engine.has_extension?
            Rust::Browser::Parts::HTTP.encode_semicolon_ext( str )
        else
            Browser::Parts::HTTP.encode_semicolon_ruby( str )
        end
    end

    def self.encode_semicolon_ruby( str )
        ::URI.encode( str, ';' )
    end

    def enforce_scope?
        !@ignore_scope
    end


end

end
end
end
