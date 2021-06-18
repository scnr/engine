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

module Environment

    # @return   [String]
    #   Filesystem directory containing the JS scripts.
    SCRIPT_LIBRARY  = "#{File.dirname( __FILE__ )}/../../javascript/scripts/"

    ENGINE_SCRIPT_TEMPLATE = "#{Options.paths.lib}/browser/engines/%s/scripts/%s"

    SCRIPT_SOURCES = Dir.glob("#{SCRIPT_LIBRARY}*.js").inject({}) do |h, path|
        h.merge!( path => IO.read( path ) )
    end

    def self.included( base )
        base.extend ClassMethods
    end

    module ClassMethods

        # @return   [String]
        #   Token used to namespace the injected JS code and avoid clashes.
        def token
            "_#{Utilities.random_seed}_scnr_engine"
        end

    end

    # @return   [String]
    #   Token used to namespace the injected JS code and avoid clashes.
    attr_accessor :token

    # @return   [String]
    #   Taints to look for and trace in the JS data flow.
    attr_accessor :taint

    # @return   [String]
    #   Inject custom JS code right after the initialization of the custom
    #   JS interfaces.
    attr_accessor :custom_code

    # @return   [Bool]
    #   `true` if there is support for our JS environment in the current page,
    #   `false` otherwise.
    #
    # @see #has_js_env?
    def supported?
        # We won't have a response if the browser was steered towards an
        # out-of-scope resource.
        response = @browser.response
        response && has_js_env?( response )
    end

    # Blocks until the browser page is {#ready? ready}.
    def wait_till_ready
        print_debug_level_2 'Waiting for JS env...'

        if !supported?
            print_debug_level_2 '...unsupported.'
            return
        end

        t = Time.now
        while !ready?
            sleep 0.05

            if Time.now - t > Options.dom.job_timeout
                print_debug_level_2 '...timed out.'
                return
            end
        end

        print_debug_level_2 '...done.'
        true
    end

    # @return   [Bool]
    #   `true` if our custom JS environment has been initialized.
    def ready?
        run( "return (typeof #{js_initializer} !== 'undefined' && document.readyState === 'complete')" )
    rescue => e
        print_debug_exception e, 2
        false
    end

    def token
        self.class.token
    end

    private

    def env_script
        return @env_script if @env_script

        @env_script = ''
        SCRIPT_SOURCES.each do |path, js|
            filename = File.basename( path )

            @env_script << "// Start system #{filename}\n"
            @env_script << replace_tokens( js )
            @env_script << "// End system #{filename}\n\n"

            engine_script = ENGINE_SCRIPT_TEMPLATE % [@browser.engine.name, filename]
            @env_script << "// Start #{@browser.engine.name} #{filename}\n"
            @env_script << read_script( engine_script )
            @env_script << "// End #{@browser.engine.name} #{filename}\n\n"
        end
        @env_script
    end

    def env_script_with_initializers( url )
        <<EOJS
// Can be included multiple times via AJAX injection etc.
// It's not a problem, just don't continue.
if( #{js_initializer} ) throw( 'Already initialized.' );

#{env_script}

// For (without query): #{url}

// Initializers
#{dom_monitor_initializer}
#{taint_tracer_initializer( url )}

function #{env_update_function} {
    #{@taint_tracer.stub.function( :update )};
    #{@dom_monitor.stub.function( :update )};
}

// Custom code
#{custom_code}

// The env has been loaded!
#{js_initialization_signal}
EOJS
    end

    def taints( url )
        taints = {}

        [@taint].flatten.compact.each do |t|
            taints[t] = {
                stop_at_first: false,
                trace:         true
            }
        end

        # Include cookie names and values in the trace so that the browser will
        # be able to infer if they're being used, to avoid unnecessary audits.
        if @browser.parse_profile.elements && Options.audit.cookie_doms?
            cookies = begin
                SCNR::Engine::HTTP::Client.cookie_jar.for_url( url )
            rescue => e
                print_debug "Could not get cookies for URL '#{url}' from Cookiejar (#{e})."
                print_debug_exception e
                SCNR::Engine::HTTP::Client.cookies
            end

            cookies.each do |c|
                next if c.http_only?

                c.inputs.to_a.flatten.each do |input|
                    next if input.empty?

                    taints[input] ||= {
                        stop_at_first: true,
                        trace:         false
                    }
                end
            end
        end

        taints
    end

end

end
end
end
end
