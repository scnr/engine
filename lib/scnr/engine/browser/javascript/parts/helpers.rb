=begin
    Copyright 2020 Tasos Laskos <tasos.laskos@gmail.com>

    This file is part of the SCNR::Engine project and is subject to
    redistribution and commercial restrictions. Please see the SCNR::Engine
    web site for more information on licensing and terms of use.
=end

module SCNR::Engine
class Browser
class Javascript
module Parts

module Helpers

    DOM_MONITOR_NO_DIGEST_ATTRIBUTE = 'data-scnr-engine-no-digest'

    def dom_monitor_no_digest_attribute
        DOM_MONITOR_NO_DIGEST_ATTRIBUTE
    end

    # Removes environment modifications from HTML code.
    #
    # @param    [String]    html
    #
    # @return   [String]
    #
    # @see Parts::Proxy#inject
    def remove_env_from_html( html )
        remove_env_from_html!( html.dup )
    end

    def remove_env_from_html!( html )
        # BEWARE!
        #
        # Careful not to remove new lines, they'll mess up the stackframe
        # line numbers!

        %w(http https).each do |proto|
            env_url = env_script_url( proto )

            # OK, this \n and the whitespace that follows it need to be removed
            # because they're added by the browsers and the stackframes are adjusted
            # for them.
            escaped_url = Regexp.escape( env_url )
            [
                # Without any other script tags in the top/head of the page.
                /<script.*?#{escaped_url}.*?<\/script>\s*\n\s*$/i,

                # Surrounded by other script tags.
                /<script.*?#{escaped_url}.*?<\/script>\s*\n\s*/i,

                # Injected into an AJAX response or something, catch-all basically.
                /<script.*?#{escaped_url}.*?<\/script>/i
            ].each do |regex|
                html.gsub!( regex, '' )
            end

            # Right after <script>
            html.gsub!(
                />#{Regexp.escape( js_line_wrapper )}.*?;/i,
                '>'
            )
            # Right before </script>
            html.gsub!(
                /;#{Regexp.escape( js_line_wrapper )}.*?;/i,
                ''
            )

            ensure_environment_removal( html, [env_url, js_line_wrapper] )
        end

        html
    end

    # Removes environment modifications from JS code.
    #
    # @param    [String]    js
    #
    # @return   [String]
    #
    # @see Parts::Proxy#inject
    def remove_env_from_js( js )
        remove_env_from_js!( js.dup )
    end

    def remove_env_from_js!( js )
        # BEWARE!
        #
        # Careful not to remove new lines, they'll mess up the stackframe
        # line numbers!

        # Beginning of JS file.
        js.sub!(
            /#{env_update_function};/i,
            ''
        )

        # End of JS file.
        js.sub!(
            /;#{env_update_function};/i,
            ''
        )

        ensure_environment_removal( js, [env_update_function] )

        js
    end

    def javascript?( response )
        response.headers.content_type.to_s.downcase.optimized_include?( 'javascript' )
    end

    def html?( response )
        return false if response.body.empty?

        # We only care about HTML responses.
        return false if !response.html?

        # The last check isn't fool-proof, so don't do it when loading the page
        # for the first time, but only when the page loads stuff via AJAX and whatnot.
        #
        # Well, we can be pretty sure that the root page will be HTML anyways.
        return true if @browser.last_url == response.url

        # Finally, verify that we're really working with markup (hopefully HTML)
        # and that the previous checks weren't just flukes matching some other
        # kind of document.
        #
        # For example, it may have been JSON with the wrong content-type that
        # includes HTML -- it happens.
        #
        # Beware, if there's a doctype in the beginning this will get fooled.
        if !Parser.markup?( response.body )
            print_debug "Does not look like HTML: #{response.url}"
            print_debug "\n#{response.body}"
            return false
        end

        true
    end

    # @return   [String]
    #   JS code which will call the `TaintTracer.log_execution_flow_sink`,
    #   browser-side, JS function.
    def log_execution_flow_sink_stub( *args )
        taint_tracer.stub.function( :log_execution_flow_sink, *args )
    end

    # @return   [String]
    #   JS code which will call the `TaintTracer.log_data_flow_sink`, browser-side,
    #   JS function.
    def log_data_flow_sink_stub( *args )
        taint_tracer.stub.function( :log_data_flow_sink, *args )
    end

    # @return   [String]
    #   JS code which will call the `TaintTracer.debug`, browser-side JS function.
    def debug_stub( *args )
        taint_tracer.stub.function( :debug, *args )
    end

    def has_sinks?
        return false if !supported?
        taint_tracer.has_sinks( @taint )
    end

    # @return   (see TaintTracer#debug)
    def debugging_data
        return [] if !supported?
        taint_tracer.debugging_data
    end

    # @return   (see TaintTracer#execution_flow_sinks)
    def execution_flow_sinks
        return [] if !supported?
        taint_tracer.execution_flow_sinks
    end

    # @return   (see TaintTracer#data_flow_sinks)
    def data_flow_sinks
        return [] if !supported?
        taint_tracer.data_flow_sinks[@taint] || []
    end

    # @return   (see TaintTracer#flush_execution_flow_sinks)
    def flush_execution_flow_sinks
        return [] if !supported?
        taint_tracer.flush_execution_flow_sinks
    end

    # @return   (see TaintTracer#flush_data_flow_sinks)
    def flush_data_flow_sinks
        return [] if !supported?
        taint_tracer.flush_data_flow_sinks[@taint] || []
    end

    # Sets a custom ID attribute to elements with events but without a proper ID.
    def set_element_ids
        return '' if !supported?
        dom_monitor.setElementIds
    end

    # @return   [String]
    #   Digest of the current DOM tree (i.e. node names and their attributes
    #   without text-nodes).
    def dom_digest
        return '' if !supported?
        dom_monitor.digest
    end

    # @return   [String]
    #   Digest of the available DOM events.
    def dom_event_digest
        return '' if !supported?
        dom_monitor.event_digest
    end

    def env_update_function
        "#{token}EnvUpdate()"
    end

    private

    def ensure_environment_removal( string, tokens )
        # Don't make the tokens dynamic, it can cause Regex leaks in Rust code!
        tokens.each do |t|
            next if !string.optimized_include?( t )

            fail "Environment removal failed: #{t}"
        end
    end

    # @param    [HTTP::Response]    response
    #   Response whose {HTTP::Message#body} to check.
    #
    # @return   [Bool]
    #   `true` if the {HTTP::Response response} {HTTP::Message#body} contains
    #   the code for the JS environment.
    def has_js_env?( response )
        response.body.optimized_include? env_script_url( response.parsed_url.scheme )
    end

    def dom_monitor_initializer
        "#{@dom_monitor.stub.function(
            :initialize,
            Options.scope.dom_event_inheritance_limit )
        };"
    end

    def taint_tracer_initializer( url )
        "#{@taint_tracer.stub.function( :initialize, taints( url ) )};"
    end

    def js_initialization_signal
        "#{js_initializer} = true;"
    end

    def wrapped_env_update_function
        "#{js_line_wrapper} #{env_update_function}"
    end

    def js_line_wrapper
        "/* #{token}RemoveLine */"
    end

    def js_initializer
        "window.#{token}"
    end

    def read_script( path )
        replace_tokens( IO.read( path ) )
    end

    def replace_tokens( str )
        str.gsub( '_token', token )
    end

end

end
end
end
end
