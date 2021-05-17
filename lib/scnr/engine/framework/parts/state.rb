=begin
    Copyright 2020 Alex Douckas <alexdouckas@gmail.com>, Tasos Laskos <tasos.laskos@gmail.com>

    This file is part of the SCNR::Engine project and is subject to
    redistribution and commercial restrictions. Please see the SCNR::Engine
    web site for more information on licensing and terms of use.
=end

module SCNR::Engine
class Framework
module Parts

# Provides access to {SCNR::Engine::State::Framework} and helpers.
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
module State

    def self.included( base )
        base.extend ClassMethods
    end

    module ClassMethods

        # @param   [String]    ses
        #   Path to an `.ses.` (SCNR::Engine Framework Snapshot) file created by
        #   {#suspend}.
        #
        # @return   [Framework]
        #   Restored instance.
        def restore( ses, &block )
            f = self.unsafe.restore( ses )
            block_given? ? f.safe( &block ) : f
        end

        # @note You should first reset {SCNR::Engine::Options}.
        #
        # Resets everything and allows the framework environment to be re-used.
        def reset
            SCNR::Engine::State.clear
            SCNR::Engine::Data.clear

            SCNR::Engine::Snapshot.reset
            SCNR::Engine::Support::Database::Base.reset
            SCNR::Engine::Platform::Manager.reset
            SCNR::Engine::Check::Auditor.reset
            ElementFilter.reset
            Element::Capabilities::Auditable.reset
            Element::Capabilities::Analyzable.reset
            Element::Capabilities::WithSinks::Sinks.reset
            Element::DOM::Capabilities::WithSinks::Sinks.reset
            SCNR::Engine::Check::Manager.reset
            SCNR::Engine::Plugin::Manager.reset
            SCNR::Engine::Reporter::Manager.reset
            HTTP::Client.reset
            SCNR::Engine::System.reset
            SCNR::Engine::Browser.reset
        end
    end

    def initialize
        super

        Element::Capabilities::Auditable.skip_like do |element|
            if pause?
                print_debug "Blocking on element audit: #{element.audit_id}"
            end

            wait_if_paused
        end

        state.status = :ready
    end

    # @return   [String]
    #   Provisioned {#suspend} dump file for this instance.
    def snapshot_path
        return @state_archive if @state_archive

        default_filename =
            "#{URI(SCNR::Engine::Options.url).host} #{Time.now.to_s.gsub( ':', '_' )} " <<
                "#{generate_token}.#{Snapshot::EXTENSION}"

        location = SCNR::Engine::Options.snapshot.path

        if !location
            location = default_filename
        elsif File.directory? location
            location += "/#{default_filename}"
        end

        @state_archive ||= File.expand_path( location )
    end

    # Cleans up the framework; should be called after running the audit or
    # after canceling a running scan.
    #
    # It stops the clock and waits for the plugins to finish up.
    def clean_up( shutdown_browsers = true )
        return if @cleaned_up
        @cleaned_up = true

        state.force_resume

        state.status = :cleanup

        if shutdown_browsers
            state.set_status_message :browser_cluster_shutdown
            shutdown_browser_cluster
        end

        state.set_status_message :clearing_queues
        page_queue.clear
        url_queue.clear

        @finish_datetime  = Time.now
        @start_datetime ||= Time.now

        state.running = false

        state.set_status_message :waiting_for_plugins
        @plugins.block

        # Plugins may need the session right till the very end so save it for last.
        @session.clean_up
        @session = nil

        true
    end

    # @private
    def reset_trainer
        @trainer = Trainer.new
    end

    # @note Prefer this from {.reset} if you already have an instance.
    # @note You should first reset {SCNR::Engine::Options}.
    #
    # Resets everything and allows the framework to be re-used.
    def reset
        @state_archive   = nil
        @cleaned_up      = false
        @browser_job     = nil
        @start_datetime  = nil
        @finish_datetime = nil
        @browser_cluster = nil

        @failures.clear
        @retries.clear

        # This needs to happen before resetting the other components so they
        # will be able to put in their hooks.
        self.class.reset

        clear_observers
        reset_trainer
        reset_session

        @checks.clear
        @reporters.clear
        @plugins.clear

        @checks    = SCNR::Engine::Check::Manager.new
        @plugins   = SCNR::Engine::Plugin::Manager.new( self )
        @reporters = SCNR::Engine::Reporter::Manager.new
    end

    # @return   [State::Framework]
    def state
        SCNR::Engine::State.framework
    end

    # @param   [String]    ses
    #   Path to an `.ses.` (SCNR::Engine Framework Snapshot) file created by {#suspend}.
    #
    # @return   [Framework]
    #   Restored instance.
    def restore( ses )
        Snapshot.load ses

        browser_job_update_skip_states state.browser_skip_states

        checks.load  SCNR::Engine::Options.checks
        plugins.load SCNR::Engine::Options.plugins.keys

        self
    end

    # @return   [Array<String>]
    #   Messages providing more information about the current {#status} of
    #   the framework.
    def status_messages
        state.status_messages
    end

    # @return   [Symbol]
    #   Status of the instance, possible values are (in order):
    #
    #   * `:ready` -- {#initialize Initialised} and waiting for instructions.
    #   * `:preparing` -- Getting ready to start (i.e. initializing plugins etc.).
    #   * `:scanning` -- The instance is currently {Framework#run auditing} the webapp.
    #   * `:pausing` -- The instance is being {#pause paused} (if applicable).
    #   * `:paused` -- The instance has been {#pause paused} (if applicable).
    #   * `:suspending` -- The instance is being {#suspend suspended} (if applicable).
    #   * `:suspended` -- The instance has being {#suspend suspended} (if applicable).
    #   * `:cleanup` -- The scan has completed and the instance is
    #       {Framework::Parts::State#clean_up cleaning up} after itself (i.e. waiting for
    #       plugins to finish etc.).
    #   * `:aborted` -- The scan has been {Framework::Parts::State#abort}, you can grab the
    #       report and shutdown.
    #   * `:done` -- The scan has completed, you can grab the report and shutdown.
    #   * `:timed_out` -- The scan was aborted due to a time-out..
    def status
        state.status
    end

    # @return   [Bool]
    #   `true` if the framework is running, `false` otherwise. This is `true`
    #   even if the scan is {#paused?}.
    def running?
        state.running?
    end

    # @return   [Bool]
    #   `true` if the system is scanning, `false` otherwise.
    def scanning?
        state.scanning?
    end

    # @return   [Bool]
    #   `true` if the framework is paused, `false` otherwise.
    def paused?
        state.paused?
    end

    # @return   [Bool]
    #   `true` if the framework has been instructed to pause (i.e. is in the
    #   process of being paused or has been paused), `false` otherwise.
    def pause?
        state.pause?
    end

    # @return   [Bool]
    #   `true` if the framework is in the process of pausing, `false` otherwise.
    def pausing?
        state.pausing?
    end

    # @return   (see SCNR::Engine::State::Framework#done?)
    def done?
        state.done?
    end

    # @note Each call from a unique caller is counted as a pause request
    #   and in order for the system to resume **all** pause callers need to
    #   {#resume} it.
    #
    # Pauses the framework on a best effort basis.
    #
    # @param    [Bool]  wait
    #   Wait until the system has been paused.
    #
    # @return   [Integer]
    #   ID identifying this pause request.
    def pause( wait = true )
        id = generate_token.hash
        state.pause id, wait
        id
    end

    # @return   [Bool]
    #   `true` if the {Framework#run} timed-out, `false` otherwise.
    def timed_out?
        state.timed_out?
    end

    # @return   [Bool]
    #   `true` if the {Framework#run} has been aborted, `false` otherwise.
    def aborted?
        state.aborted?
    end

    # @return   [Bool]
    #   `true` if the framework has been instructed to abort (i.e. is in the
    #   process of being aborted or has been aborted), `false` otherwise.
    def abort?
        state.abort?
    end

    # @return   [Bool]
    #   `true` if the framework is in the process of aborting, `false` otherwise.
    def aborting?
        state.aborting?
    end

    # Aborts the {Framework#run} on a best effort basis.
    #
    # @param    [Bool]  wait
    #   Wait until the system has been aborted.
    def abort( wait = true )
        state.abort wait
    end

    # @note Each call from a unique caller is counted as a pause request
    #   and in order for the system to resume **all** pause callers need to
    #   {#resume} it.
    #
    # Removes a {#pause} request for the current caller.
    #
    # @param    [Integer]   id
    #   ID of the {#pause} request.
    def resume( id )
        state.resume id
    end

    # Writes a {Snapshot.dump} to disk and aborts the scan.
    #
    # @param   [Bool]  wait
    #   Wait for the system to write it state to disk.
    #
    # @return   [String,nil]
    #   Path to the state file `wait` is `true`, `nil` otherwise.
    def suspend( wait = true )
        state.suspend( wait )
        return snapshot_path if wait
        nil
    end

    # @return   [Bool]
    #   `true` if the system is in the process of being suspended, `false`
    #   otherwise.
    def suspend?
        state.suspend?
    end

    # @return   [Bool]
    #   `true` if the system has been suspended, `false` otherwise.
    def suspended?
        state.suspended?
    end

    private

    # @note Must be called before calling any audit methods.
    #
    # Prepares the framework for the audit.
    #
    # * Sets the status to `:preparing`.
    # * Starts the clock.
    # * Runs the plugins.
    def prepare
        state.status  = :preparing
        state.running = true
        @start_datetime = Time.now

        Snapshot.restored? ? @plugins.restore : @plugins.run
    end

    def reset_session
        @session.clean_up if @session
        @session = Session.new
    end

    # Small but (sometimes) important optimization:
    #
    # Keep track of page elements which have already been passed to checks,
    # in order to filter them out and hopefully even avoid running checks
    # against pages with no new elements.
    #
    # It's not like there were going to be redundant audits anyways, because
    # each layer of the audit performs its own redundancy checks, but those
    # redundancy checks can introduce significant latencies when dealing
    # with pages with lots of elements.
    def pre_audit_element_filter( page )
        unique_elements  = {}
        page.elements.each do |e|
            next if !SCNR::Engine::Options.audit.element?( e.type )
            next if e.is_a?( Cookie ) || e.is_a?( Header )

            new_element               = false
            unique_elements[e.type] ||= []

            if !state.element_checked?( e )
                state.element_checked e
                new_element = true
            end

            if page.dom.depth > 0 && e.respond_to?( :dom ) && e.dom
                if !state.element_checked?( e.dom )
                    state.element_checked e.dom
                    new_element = true
                end
            end

            next if !new_element

            unique_elements[e.type] << e
        end

        # Remove redundant elements from the page cache, if there are thousands
        # of them then just skipping them during the audit will introduce latency.
        unique_elements.each do |type, elements|
            page.send( "#{type}s=", elements )
        end

        page
    end

    def handle_signals
        wait_if_paused
        abort_if_signaled
        abort_if_timeout
        suspend_if_signaled
    end

    def wait_if_paused
        state.paused if pause?
        sleep 0.2 while pause? && !abort?
    end

    def abort_if_signaled
        return if !abort?
        clean_up
        state.aborted
    end

    def abort_if_timeout
        return if @start_datetime && !SCNR::Engine::Options.timeout.exceeded?(
          Time.now - @start_datetime
        )

        if SCNR::Engine::Options.timeout.suspend?
            suspend_to_disk
        else
            clean_up
            state.timed_out
        end
    end

    def suspend_if_signaled
        return if !suspend?
        suspend_to_disk
    end

    def suspend_to_disk
        options = SCNR::Engine::Options

        options.timeout.duration = nil
        options.timeout.suspend  = nil

        if @browser_cluster
            state.set_status_message :waiting_for_browser_cluster_jobs, @browser_cluster.workers.size
            @browser_cluster.shutdown_for_suspend
        end

        # Make sure the component options are up to date with what's actually
        # happening.
        options.checks  = checks.loaded
        options.plugins = plugins.loaded.
            inject({}) { |h, name| h[name.to_s] =
                options.plugins[name.to_s] || {}; h }

        if browser_cluster_job_skip_states
            state.browser_skip_states.merge browser_cluster_job_skip_states
        end

        state.set_status_message :suspending_plugins
        @plugins.suspend

        state.set_status_message :saving_snapshot, snapshot_path
        Snapshot.dump( snapshot_path )
        state.clear_status_messages

        clean_up

        state.set_status_message :snapshot_location, snapshot_path
        print_info status_messages.first
        state.suspended
    end

end

end
end
end
