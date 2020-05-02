=begin
    Copyright 2020 Alex Douckas <alexdouckas@gmail.com>, Tasos Laskos <tasos.laskos@gmail.com>

    This file is part of the SCNR::Engine project and is subject to
    redistribution and commercial restrictions. Please see the SCNR::Engine
    web site for more information on licensing and terms of use.
=end

module SCNR::Engine

# @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
class BrowserCluster
    include UI::Output
    include Utilities

    prepend Support::Mixins::SpecInstances

    personalize_output!

    # {BrowserCluster} error namespace.
    #
    # All {BrowserCluster} errors inherit from and live under it.
    #
    # @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
    class Error < SCNR::Engine::Error

        # Raised when a method is called after the {BrowserCluster} has been
        # {BrowserCluster#shutdown}.
        #
        # @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
        class AlreadyShutdown < Error
        end

        # Raised when a given {Job} could not be found.
        #
        # @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
        class JobNotFound < Error
        end
    end

    lib = Options.paths.lib
    require lib + 'browser_cluster/worker'
    require lib + 'browser_cluster/job'

    # Holds {BrowserCluster} {Job} types.
    #
    # @see BrowserCluster#queue
    #
    # @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
    module Jobs
    end

    # Load all job types.
    Dir[lib + 'browser_cluster/jobs/*'].each { |j| require j }

    # Default pool-size.
    POOL_SIZE = 1

    # @return   [Integer]
    #   Amount of browser instances in the pool.
    attr_accessor :pool_size

    attr_accessor :on_queue
    attr_accessor :on_pop
    attr_accessor :on_job_done

    # @return   [Array<Worker>]
    #   Worker pool.
    attr_reader :workers

    # @return   [Integer]
    #   Number of pending jobs.
    attr_reader :pending_job_counter

    # @param    [Hash]  options
    # @option   options [Integer]   :pool_size (POOL_SIZE)
    #   Amount of {Worker browsers} to add to the pool.
    def initialize( options = {}, &block )
        options.each do |k, v|
            send( "#{k}=", v )
        end

        @pool_size ||= POOL_SIZE

        # Callbacks for each job per Job#id. We need to keep track of this
        # here because jobs are serialized and off-loaded to disk and thus can't
        # contain Block or Proc objects.
        @job_callbacks = State.browser_cluster.job_callbacks

        # Keeps track of the amount of pending jobs distributed across the
        # cluster, by Job#id. Once a job's count reaches 0, it's passed to
        # #job_done.
        @pending_jobs = State.browser_cluster.pending_jobs

        @jobs = Data.browser_cluster.job_queue
        @jobs.prefer = block || proc{}

        # Worker pool holding BrowserCluster::Worker instances.
        @workers     = []

        @mutex       = Monitor.new
        @done_signal = Queue.new

        initialize_workers
    end

    # @return   [String]
    #   Javascript token used to namespace the custom JS environment.
    def javascript_token
        Browser::Javascript.token
    end

    def with_browser( *args, &block )
        api_change_guard( &block )

        method_handler = args.pop
        if !method_handler.is_a?( Method )
            fail ArgumentError, 'Missing callback method.'
        end

        queue( Jobs::BrowserProvider.new( args ), method_handler )
    end

    def with_browser_and_tap( tap, *args, &block )
        api_change_guard( &block )

        method_handler = args.pop
        if !method_handler.is_a?( Method )
            fail ArgumentError, 'Missing callback method.'
        end

        queue( Jobs::BrowserProvider.new( args ).tap(&tap), method_handler )
    end

    # @param    [Job]  job
    # @param    [Method]  cb
    #   Callback to be passed the {Job::Result}.
    #   Must be a class method in order to support suspend to disk.
    #
    # @raise    [AlreadyShutdown]
    # @raise    [Job::Error::AlreadyDone]
    def queue( job, cb, &block )
        api_change_guard( &block )

        if !cb.receiver.is_a?( Class ) && !cb.receiver.is_a?( Module )
            fail ArgumentError, 'Callback must be a class method.'
        end

        fail_if_shutdown
        fail_if_job_done job

        @done_signal.clear

        synchronize do
            print_debug "Queueing: #{job}"

            notify_on_queue job

            self.class.increment_queued_job_count

            State.browser_cluster.pending_job_counter += 1
            @pending_jobs[job.id] += 1

            @job_callbacks[job.id] = cb

            @jobs << job
        end

        nil
    end

    # @param    [Page, String, HTTP::Response]  resource
    #   Resource to explore, if given a `String` it will be treated it as a URL
    #   and will be loaded.
    # @param    [Hash]  options
    #   See {Jobs::DOMExploration} accessors.
    #
    # @see Jobs::DOMExploration
    # @see #queue
    def explore( resource, options = {}, cb, &block )
        api_change_guard( &block )

        queue(
            Jobs::DOMExploration.new( options.merge( resource: resource ) ),
            cb
        )
    end

    # @param    [Page, String, HTTP::Response] resource
    #   Resource to load and whose environment to trace, if given a `String` it
    #   will be treated it as a URL and will be loaded.
    # @param    [Hash]  options
    #   See {Jobs::TaintTrace} accessors.
    #
    # @see Jobs::TaintTrace
    # @see #queue
    def trace_taint( resource, options = {}, cb, &block )
        api_change_guard( &block )

        queue(
            Jobs::TaintTrace.new( options.merge( resource: resource ) ),
            cb
        )
    end

    # @param    [Job]  job
    #   Job to mark as done. Will remove any callbacks and associated
    #   {Worker} states.
    def job_done( job )
        synchronize do
            print_debug "Job done: #{job}"

            State.browser_cluster.pending_job_counter -= 1
            @pending_jobs[job.id] -= 1

            increment_completed_job_count
            add_to_total_job_time( job.time )

            notify_on_job_done job

            if !job.never_ending?
                @job_callbacks.delete job.id
            end

            if State.browser_cluster.pending_job_counter == 0
                print_debug_level_2 'Pending job counter reached 0.'
                @done_signal << nil
            end
        end
    end

    # @param    [Job]  job
    #
    # @return   [Bool]
    #   `true` if the `job` has been marked as finished, `false` otherwise.
    #
    # @raise    [Error::JobNotFound]  Raised when `job` could not be found.
    def job_done?( job, fail_if_not_found = true )
        return false if job.never_ending?

        synchronize do
            fail_if_job_not_found job if fail_if_not_found
            return false if !@pending_jobs.include?( job.id )
            @pending_jobs[job.id] == 0
        end
    end

    # @param    [Job::Result]  result
    #
    # @private
    def handle_job_result( result )
        return if @shutdown
        return if job_done? result.job

        synchronize do
            print_debug "Got job result: #{result}"

            exception_jail( false ) do
                @job_callbacks[result.job.id].call( *[
                    result,
                    result.job.args,
                    self
                ].flatten.compact)
            end
        end

        nil
    end

    # @return   [Bool]
    #   `true` if there are no resources to analyze and no running workers.
    def done?
        fail_if_shutdown
        synchronize { State.browser_cluster.pending_job_counter == 0 }
    end

    def pending_job_counter
        synchronize { State.browser_cluster.pending_job_counter }
    end

    # Blocks until all resources have been analyzed.
    def wait
        fail_if_shutdown

        print_debug 'Waiting to finish...'
        @done_signal.pop if !done?
        print_debug '...finish.'

        self
    end

    # Shuts the cluster down.
    def shutdown( wait = true )
        print_debug 'Shutting down...'
        @shutdown = true

        print_debug_level_2 'Clearing jobs...'
        # Clear the jobs -- don't forget this, it also removes the disk files for
        # the contained items.
        @jobs.clear
        print_debug_level_2 '...done.'

        print_debug_level_2 "Shutting down #{@workers.size} workers..."
        # Kill the browsers.
        @workers.each { |b| exception_jail( false ) { b.shutdown wait } }
        @workers.clear
        print_debug_level_2 '...done.'

        print_debug_level_2 'Clearing data and state...'
        # Very important to leave these for last, they may contain data
        # necessary to cleanly handle interrupted jobs.
        @job_callbacks.clear
        @pending_jobs.clear
        print_debug_level_2 '...done.'

        print_debug '...shutdown complete.'
        true
    end

    def shutdown_for_suspend
        @workers.each do |b|
            exception_jail( false ) { b.shutdown }
        end
        @workers.clear
        nil
    end

    # @return    [Job]
    #   Pops a job from the queue.
    #
    # @see #queue
    # @private
    def pop
        print_debug 'Popping...'
        {} while job_done?( job = @jobs.pop )
        print_debug "...popped: #{job}"

        notify_on_pop job

        job
    end

    # @private
    def callback_for( job )
        @job_callbacks[job.id]
    end

    def increment_queued_job_count
        self.class.increment_queued_job_count
    end

    def increment_completed_job_count
        self.class.increment_completed_job_count
    end

    def increment_time_out_count
        self.class.increment_time_out_count
    end

    def add_to_total_job_time( time )
        self.class.add_to_total_job_time( time )
    end

    def self.seconds_per_job
        n = (total_job_time / Float( completed_job_count ))
        n.nan? ? 0 : n
    end

    def self.increment_queued_job_count
        State.browser_cluster.increment_queued_job_count
    end

    def self.increment_completed_job_count
        State.browser_cluster.increment_completed_job_count
    end

    def self.increment_time_out_count
        State.browser_cluster.increment_time_out_count
    end

    def self.completed_job_count
        State.browser_cluster.completed_job_count
    end

    def self.time_out_count
        State.browser_cluster.time_out_count
    end

    def self.queued_job_count
        State.browser_cluster.queued_job_count
    end

    def self.total_job_time
        State.browser_cluster.total_job_time
    end

    def self.add_to_total_job_time( time )
        State.browser_cluster.add_to_total_job_time time
    end

    def self.statistics
        {
            seconds_per_job:     seconds_per_job,
            total_job_time:      total_job_time,
            queued_job_count:    queued_job_count,
            completed_job_count: completed_job_count,
            time_out_count:      time_out_count
        }
    end

    private

    def api_change_guard( &block )
        if block_given?
            fail ArgumentError, 'API change, no blocks allowed.'
        end
    end

    def notify_on_queue( job )
        return if !@on_queue
        @on_queue.call job
    end

    def notify_on_job_done( job )
        return if !@on_job_done

        @on_job_done.call job
    end

    def notify_on_pop( job )
        return if !@on_pop

        @on_pop.call job
    end

    def fail_if_shutdown
        fail Error::AlreadyShutdown, 'Cluster has been shut down.' if @shutdown
    end

    def fail_if_job_done( job )
        return if !job_done?( job, false )
        fail Job::Error::AlreadyDone, 'Job has been marked as done.'
    end

    def fail_if_job_not_found( job )
        return if @pending_jobs.include?( job.id )
        fail Error::JobNotFound, 'Job could not be found.'
    end

    def synchronize( &block )
        @mutex.synchronize( &block )
    end

    def initialize_workers
        print_status "Initializing #{pool_size} #{Options.browser_cluster.engine.capitalize} browsers..."

        @workers = []
        pool_size.times do |i|
            worker = Worker.new(
                master: self,
                width:  Options.device.width,
                height: Options.device.height
            )
            @workers << worker
            print_status "Spawned ##{i+1} with PID #{worker.engine.pid} " <<
                "[lifeline at PID #{worker.engine.lifeline_pid}]."
        end

        print_status "Initialization completed with #{@workers.size} browsers in the pool."
    end

    def self._spec_instance_cleanup( i )
        i.shutdown false
    end

end
end
