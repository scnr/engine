=begin
    Copyright 2020-2022 Tasos Laskos <tasos.laskos@gmail.com>

    This file is part of the SCNR::Engine project and is subject to
    redistribution and commercial restrictions. Please see the SCNR::Engine
    web site for more information on licensing and terms of use.
=end

module SCNR::Engine
module Element::Capabilities
module Analyzable

# Evaluates whether or not the injection of specific data affects the response
# time of the web application.
#
# It takes into account unstable network conditions and server-side failures and
# verifies the results before logging.
#
# Be sure to call {.run} as soon as possible after Phase 1, as the candidate
# elements keep a reference to their auditor which will prevent it from being
# garbage collected.
#
# This deviates from the normal framework structure because it is preferable
# to run timeout audits separately in order to avoid interference by other
# audit operations.
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
module Timeout

    # Override user audit options that don't play nice with this technique.
    TIMEOUT_OPTIONS =  {
        skip_original:          true,
        with_both_http_methods: false,
        parameter_names:        false,
        with_extra_parameter:   false,
        extensively:            false
    }

    # Delay multipliers for each verification phase.
    TIMEOUT_PHASES = [6, 1, 3, 2, 4, 5, 1]

    class <<self
        def reset
            # We can track out own candidate state here, without registering it
            # with the global system State, because everything that happens
            # here is green-lit by #timing_attack_probe, which does register
            # its state as it uses #audit.
            #
            # Also, candidates will be consumed prior to a suspension, so when
            # we suspend and restore scans there will be no issue.

            @candidates    = []
            @candidate_ids = []
            @logged        = Support::Filter::Set.new(hasher: :timeout_hash )

            TIMEOUT_PHASES.each.with_index do |t, i|
                @candidates[i]    = []
                @candidate_ids[i] = Support::Filter::Set.new(hasher: :timeout_hash )
            end

            deduplicate
        end

        def calculate_cost( payloads_size, options = {} )
            Auditable.calculate_cost( payloads_size, options )
        end

        def deduplicate?
            @deduplicate
        end

        def deduplicate
            @deduplicate = true
        end

        # Used just for specs of timing-attack checks.
        def do_not_deduplicate
            @deduplicate = false
        end

        # Verifies and logs candidate elements.
        def run
            @candidates.each.with_index do |candidates, i|
                while (candidate = candidates.pop)
                    next if Timeout.deduplicate? && logged?( candidate )

                    send( "analysis_phase_#{i+1}", candidate )
                end
            end
        end

        def payload_delay_from_options( options )
            (options[:delay] / options[:timeout_divider]).to_s
        end

        def timeout_from_options( options )
            options[:delay] + options[:timeout_add]
        end

        def has_candidates?
            @candidates[0].any?
        end

        def candidates_include?( candidate )
            @candidate_ids[0].include? candidate
        end

        TIMEOUT_PHASES.each.with_index do |_, i|
            define_method "add_phase_#{i+1}_candidate" do |elem|
                @candidate_ids[i] << elem
                @candidates[i]    << elem
            end
        end

        private

        TIMEOUT_PHASES[0...-1].each.with_index do |multiplier, i|
            define_method "analysis_phase_#{i+1}"  do |elem|
                delay = elem.audit_options[:delay] * multiplier

                elem.print_status "Phase #{i+1}/#{TIMEOUT_PHASES.size} for #{elem.type} input " <<
                    "'#{elem.affected_input_name}' with action #{elem.action}"
                elem.print_info "Original delay: #{elem.audit_options[:delay]} " <<
                    "- Multiplier: #{multiplier} - Effective delay: #{delay} "

                elem.timing_attack_verify( delay ) do
                    elem.print_info '* Verification was successful, candidate can ' <<
                        "progress to Phase #{i+2}."

                    send( "add_phase_#{i+2}_candidate", elem )
                end
            end
        end

        define_method "analysis_phase_#{TIMEOUT_PHASES.size}" do |elem|
            delay = elem.audit_options[:delay] * TIMEOUT_PHASES.last

            elem.print_status "Phase #{TIMEOUT_PHASES.size}/#{TIMEOUT_PHASES.size}" <<
                " for #{elem.type} input '#{elem.affected_input_name}' with action #{elem.action}"
            elem.print_info "Original delay: #{elem.audit_options[:delay]} " <<
                "- Multiplier: #{TIMEOUT_PHASES.last} - Effective delay: #{delay} "

            elem.timing_attack_verify( delay ) do |response|
                # Update the payload stub with a real value, for the user's
                # sake at this point.
                elem.seed = elem.seed.gsub(
                    '__TIME__', payload_delay_from_options( elem.audit_options )
                )

                @logged << elem

                remarks = []

                delays = elem.timing_attack_remark_data[:delays].
                    map { |d| d / 1000.0 }
                remarks << ('Delays (in seconds) used for each phase: ' <<
                    delays.join(', '))

                controls = elem.timing_attack_remark_data[:control_times]
                remarks << ('Response times (in seconds) for control requests :' <<
                    controls.join( ', ' ))

                stabilizations = elem.timing_attack_remark_data[:stabilization_times]
                remarks << ('Response times (in seconds) for stabilization ' <<
                    "requests after each phase: #{stabilizations.join(', ')}")

                elem.print_info '* Verification was successful.'
                elem.auditor.log(
                    vector:   elem,
                    response: response,
                    remarks:  { timing_attack: remarks }
                )
            end
        end

        # @param    [Element::Capabilities::Analyzable::Timeout]    element
        #
        # @return   [Bool]
        #   `true` if the element has logged an issue, `false` otherwise.
        def logged?( element )
            @logged.include? element
        end
    end

    attr_accessor :timing_attack_remark_data

    def initialize(*)
        super

        @timing_attack_remark_data = {
            control_times:       [],
            stabilization_times: [],
            delays:              []
        }
    end

    # Performs timeout/time-delay analysis and logs an issue should there be one.
    #
    # @param  [String, Array<String>, Hash{Symbol => <String, Array<String>>}]  payloads
    #   Payloads to inject, if given:
    #
    #   * {String} -- Will inject the single payload.
    #   * {Array} -- Will iterate over all payloads and inject them.
    #   * {Hash} -- Expects {Platform} (as `Symbol`s ) for keys and {Array} of
    #       `payloads` for values. The applicable `payloads` will be
    #       {Platform::Manager#pick picked} from the hash based on
    #       {Element::Capabilities::WithPlatforms#platforms applicable platforms}
    #       for the {Element::Capabilities::Submittable#action resource} to be audited.
    #
    #   Delay stub `__TIME__` will be substituted with `timeout / timeout_divider`.
    # @param   [Hash]      opts
    #   Options as described in {Element::Capabilities::Mutable::MUTATION_OPTIONS}
    #   with the specified extras.
    # @option   opts    [Integer] :timeout
    #   Milliseconds to wait for the request to complete.
    # @option   opts    [Integer] :timeout_divider (1)
    #   `__TIME__ = timeout / timeout_divider`
    # @option   opts    [Integer] :timeout_add (0)
    #   Add this integer to the expected time the request is supposed to take,
    #   in milliseconds.
    #
    # @return   [Bool]
    #   `true` if the audit was scheduled successfully, `false` otherwise (like
    #   if the resource is out of scope).
    def timeout_analysis( payloads, opts )
        return false if self.inputs.empty?

        if scope.out?
            print_debug "Element is out of scope skipping: #{audit_id}"
            return false
        end

        timing_attack_probe( payloads, opts ) do |elem|
            next if Timeout.deduplicate? && Timeout.candidates_include?( elem )

            print_info 'Found a candidate for Phase 1 -- ' <<
                "#{elem.type.capitalize} input '#{elem.affected_input_name}' " <<
                "pointing to: #{elem.action}"
            print_verbose "Using: #{elem.affected_input_value.inspect}"

            Timeout.add_phase_1_candidate( elem )
        end

        true
    end

    def timeout_id
        "#{audit_id( self.affected_input_value )}:#{self.affected_input_name}"
    end

    def timeout_hash
        timeout_id.hash
    end

    # Submits self with a high timeout value and blocks until it gets a response.
    #
    # This is to make sure that responsiveness has been restored before
    # progressing further in the timeout analysis.
    #
    # @param    [Integer] limit
    #   How many milliseconds to afford the server to respond.
    #
    # @return   [Bool]
    #   `true` if server responds within the given time limit, `false` otherwise.
    def ensure_responsiveness( limit = 120_000, prepend = '* ' )
        options = {
            timeout:           limit,
            mode:              :sync,
            response_max_size: 0
        }

        print_info "#{prepend}Waiting for the effects of the previous timing " <<
            'attack to wear off, this may take a while (max waiting time is ' <<
             "#{options[:timeout] / 1000.0} seconds)."

        response = timeout_control.submit( options )

        if response.timed_out? || response.partial?
            print_bad "#{prepend}Max waiting time exceeded."
            false
        else
            @timing_attack_remark_data[:stabilization_times] << response.time

            print_info "#{prepend}OK, got a response in #{response.time} seconds."
            true
        end
    end

    # Performs a simple probe for elements whose submission results in a
    # response time that matches the delay criteria in `options`.
    #
    # @param    (see #timeout_analysis)
    def timing_attack_probe( payloads, options, &block )
        fail ArgumentError, 'Missing block' if !block_given?

        options                     = options.merge( TIMEOUT_OPTIONS )
        options[:delay]             = options.delete(:timeout)
        options[:timeout_divider] ||= 1
        options[:timeout_add]     ||= 0

        # Intercept each element mutation prior to it being submitted and
        # replace the '__TIME__' stub with the actual delay value.
        options[:each_mutation] = proc do |mutation|
            injected = mutation.affected_input_value

            # Preserve the placeholder (__TIME__) payload because it's going to
            # be needed for the verification phases...
            mutation.audit_options[:timing_string] = injected

            # ...but update it to use a real payload for this audit.
            mutation.affected_input_value = injected.
                gsub( '__TIME__', payload_delay_from_options( options ) )
        end

        # Ignore response bodies to preserve bandwidth since we don't care
        # about them anyways.
        options[:submit] = {
            response_max_size: 0,
            timeout:           timeout_from_options( options ),
        }

        if debug_level_2?
            print_debug_level_2 "#{options}"
        end

        audit( payloads, options ) do |response, mutation|
            next if !response.timed_out? || response.partial?

            mutation.timing_attack_remark_data[:delays] << options[:delay]
            block.call( mutation, response )
        end
    end

    # Verifies that response times are controllable for elements picked by
    # {#timing_attack_probe}.
    #
    # * Liveness check: Element is submitted as is with a  very high timeout
    #   value, to make sure that (or wait until) the server is alive to
    #   {#ensure_responsiveness}.
    # * Control check: Element is, again,  submitted as is, although this time
    #   with a timeout value of `delay` to ensure that the server is stable
    #   enough to be checked.
    #   * If this fails the check is aborted.
    # * Verification: Element is submitted with an increased delay to verify
    #   the vulnerability.
    #   * If verification succeeds the `block` is called.
    # * Stabilize responsiveness: Wait for the effects of the timing attack
    #   to wear off by calling {#ensure_responsiveness}.
    #
    # @param    [Integer]   delay
    # @param    [Block]     block
    def timing_attack_verify( delay, &block )
        fail ArgumentError, 'Missing block' if !block_given?

        options         = self.audit_options.dup
        options[:delay] = delay

        # Actual value to use for the server-side delay operation.
        payload_delay = payload_delay_from_options( options )

        # Prepared payload, which will hopefully introduce a server-side delay.
        payload = options[:timing_string].gsub( '__TIME__', payload_delay )

        # Timeout value (in milliseconds) for the HTTP request.
        timeout = timeout_from_options( options )

        # Make sure we're starting off with a clean slate.
        ensure_responsiveness

        # This is the control; submits the element with its default (or sample,
        # if its defaults are empty) values and ensures that element submission
        # doesn't time out by default.
        #
        # If it does, then there's no way for us to test it reliably.
        if_timeout_control_check_ok seed, timeout do

            # Update our candidate mutation's affected input with the new payload.
            self.affected_input_value = payload

            print_verbose "  * Payload delay:   #{payload_delay}"
            print_verbose "  * Request timeout: #{timeout}"
            print_verbose "  * Payload:         #{payload.inspect}"

            submit( response_max_size: 0, timeout: timeout ) do |response|
                if !response.timed_out? || response.partial?
                    print_info "* Verification failed, got response in #{response.time} seconds."
                    next
                end

                @timing_attack_remark_data[:delays] << timeout
                block.call( response )

                ensure_responsiveness
            end
        end

        http.run
    end

    def dup
        e = super
        return e if !@timing_attack_remark_data

        dupped_remark_data = {}
        @timing_attack_remark_data.each do |k, v|
            dupped_remark_data[k] = v.dup
        end

        e.timing_attack_remark_data = dupped_remark_data
        e
    end

    def to_rpc_data
        super.tap { |data| data.delete 'timing_attack_remark_data' }
    end

    private

    def if_timeout_control_check_ok( seed, timeout, &block )
        print_info '* Performing control check.'

        # Use a real payload with a delay of 0, this way we can avoid getting
        # tricked by WAFs/IDS/IPS dropping packets.
        self.affected_input_value = seed.sub( '__TIME__', '0' )
        submit( response_max_size: 0, timeout: timeout ) do |control|
            if control.timed_out? || control.partial?
                print_info '* Control check failed, aborting.'
                next
            end

            @timing_attack_remark_data[:control_times] << control.time

            print_info '* Control check was successful, progressing' <<
                           ' to verification.'

            block.call
        end
    end

    def timeout_control
        self.dup.reset.tap { |e| Options.input.fill( e ) }
    end

    def payload_delay_from_options( *args )
        Timeout.payload_delay_from_options( *args )
    end

    def timeout_from_options( *args )
        Timeout.timeout_from_options( *args )
    end

end
end
end
end
