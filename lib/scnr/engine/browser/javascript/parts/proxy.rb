=begin
    Copyright 2024 Ecsypno Single Member P.C.

    This file is part of the SCNR::Engine project and is subject to
    redistribution and commercial restrictions. Please see the SCNR::Engine
    web site for more information on licensing and terms of use.
=end

module SCNR::Engine
class Browser
class Javascript
module Parts

module Proxy

    # @return   [String]
    #   URL to use when requesting our custom JS scripts.
    SCRIPT_BASE_URL = 'javascript.browser.scnr.engine/'

    ENV_SCRIPT_URL  = "#{SCRIPT_BASE_URL}env.js"
    ENV_SCRIPT_DATA_START = 'scnr_engine_start_'
    ENV_SCRIPT_DATA_END   = '_scnr_engine_end'

    def self.included( base )
        base.extend ClassMethods
    end

    module ClassMethods
        def env_script_url( proto )
            "#{proto}://#{ENV_SCRIPT_URL}"
        end
    end

    # @param    [HTTP::Request]     request
    #   Request to process.
    # @param    [HTTP::Response]    response
    #   Response to populate.
    #
    # @return   [Bool]
    #   `true` if the request corresponded to a JS file and was served,
    #   `false` otherwise.
    #
    # @see ENV_SCRIPT_URL
    def serve( request, response )
        without_query, query = request.url.split( '?', 2 )
        return false if without_query != self.class.env_script_url( request.parsed_url.scheme )

        parent_url = @browser.last_url

        if query
            # Other scripts would append cache queries.
            query = query.scan( /#{ENV_SCRIPT_DATA_START}(.*)#{ENV_SCRIPT_DATA_END}/ ).first

            if query && query.first
                parent_url = Base64.urlsafe_decode64( query.first )
            end

        end

        script = env_script_with_initializers( parent_url )

        response.code = 200
        response.body = script
        response.headers['cache-control']  = 'no-store'
        response.headers['content-type']   = 'text/javascript'
        response.headers['content-length'] = script.bytesize

        true
    end

    # @note Will update the `Content-Length` header field.
    #
    # @param    [HTTP::Response]    response
    #   Installs our custom JS interfaces in the given `response`.
    #
    # @see ENV_SCRIPT_URL
    def inject( response )
        # Don't intercept our own stuff!
        return if response.url.start_with?( self.class.env_script_url( response.parsed_url.scheme ) )
        # HTML but already has the JS env.
        return if has_js_env?( response )

        # BEWARE!
        #
        # Careful not to introduce any extra new lines, they'll mess up the
        # stackframe lines!

        # If it's a JS file, update our JS interfaces in case it has stuff that
        # can be tracked.
        #
        # This is necessary because new files can be required dynamically.
        if response.javascript?

            response.body.insert 0, "#{env_update_function};"
            response.body << ";#{env_update_function};"

        elsif self.class.html?( response )

            # Perform an update before each script runs.
            response.body.gsub!(
                /<script.*?>/i,
                "\\0#{wrapped_env_update_function};"
            )

            # Perform an update after each script has run.
            response.body.gsub!(
                /<\/script>/i,
                ";#{wrapped_env_update_function};\\0"
            )

            # Don't need the query, cookies only care about paths and a large
            # query will just make things look weird.
            encoded_cookie_taint_url = Base64.urlsafe_encode64(
                response.parsed_url.without_query
            )

            env_script = "<script #{self.class.dom_monitor_no_digest_attribute}=\"true\" " <<
                "src=\"#{self.class.env_script_url( response.parsed_url.scheme )}?#{ENV_SCRIPT_DATA_START}" <<
                "#{encoded_cookie_taint_url}#{ENV_SCRIPT_DATA_END}\"></script>"

            # Include our JS env.
            response.body.insert 0, env_script
        end

        true
    end

end

end
end
end
end
