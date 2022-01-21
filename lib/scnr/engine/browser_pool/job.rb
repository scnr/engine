=begin
    Copyright 2020-2022 Tasos Laskos <tasos.laskos@gmail.com>

    This file is part of the SCNR::Engine project and is subject to
    redistribution and commercial restrictions. Please see the SCNR::Engine
    web site for more information on licensing and terms of use.
=end

require_relative 'job/result'

module SCNR::Engine
class BrowserPool

# Represents a job to be passed to the {BrowserPool#queue} for deferred
# execution.
#
# @abstract
# @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
class Job

    # {Job} error namespace.
    #
    # All {Job} errors inherit from and live under it.
    #
    # @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
    class Error < BrowserPool::Error

        # Raised when a finished {Job} is {BrowserPool#queue queued}.
        #
        # @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
        class AlreadyDone < Error
        end
    end

    # @return   [Worker]
    #   Browser to use in order to perform the relevant {#run task} -- set by
    #   {Worker#run_job} via {#configure_and_run}.
    attr_reader :browser

    # @return   [Job]
    #   Forwarder [Job] in case `self` is a result of a forward operation.
    #
    # @see #forward
    # @see #forward_as
    attr_accessor :forwarder

    # @return   [Integer]
    #   Duration of the job, in seconds.
    attr_accessor :time

    # @return   [Browser::ParseProfile]
    attr_accessor :parse_profile

    # @return   [Array]
    attr_accessor :args

    # @return   [Symbol]
    #   Category for {Support::Database::CategorizedQueue}.
    attr_accessor :category

    attr_accessor :skip_states

    # @param    [Hash]  options
    def initialize( options = {} )
        @options      = options.dup
        @options[:id] = @id = options.delete(:id) || State.browser_pool.increment_job_id

        @args        = @options[:args] || []
        @skip_states = @options[:skip_states] ||
            Support::Filter::Set.new(hasher: :persistent_hash )

        options.each { |k, v| options[k] = send( "#{k}=", v ) }
    end

    # @param    [Integer]   time
    #   Amount of {#time} elapsed until time-out.
    def timed_out!( time )
        @timed_out = true
        @time = time
    end

    # @return   [Bool]
    #   `true` if timed-ot, `false` otherwise.
    def timed_out?
        !!@timed_out
    end

    # @note The following resources will be available at the time of execution:
    #
    #       * {#browser}
    #
    # Encapsulates the job payload.
    #
    # @abstract
    def run
    end

    # @return   [Bool]
    #   `true` if this job never ends, `false` otherwise.
    #
    # @see #never_ending
    def never_ending?
        !!@never_ending
    end

    # @return   [Bool]
    #   `true` if this job never ends, `false` otherwise.
    def never_ending=( bool )
        @options[:never_ending] = bool
        @never_ending = bool
    end

    # Configures the job with the given resources, {#run runs} the payload
    # and then removes the assigned resources.
    #
    # @param    [Worker]  browser
    #   {#browser Browser} to use in order to perform the relevant task -- set
    #   by {BrowserPool::Worker#run_job}.
    def configure_and_run( browser )
        set_resources( browser )
        run
    ensure
        remove_resources
    end

    # Forwards the {Result resulting} `data` to the
    # {BrowserPool#handle_job_result browser cluster} which then forwards
    # it to the entity that {BrowserPool#queue queued} the job.
    #
    # The result type will be the closest {Result} class to the {Job} type.
    # If the job is of type `MyJob`, `MyJob::Result` will be used, the default
    # if {Result}.
    #
    # @param    [Hash]  data
    #   Used to initialize the {Result}.
    def save_result( data )
        # Results coming in after the job has already finished won't have a
        # browser.
        return if !browser

        browser.master.handle_job_result(
            self.class::Result.new( data.merge( job: self.clean_copy ) )
        )
        nil
    end

    # @return   [Job]
    #   {#dup Copy} of `self` with any resources set by {#configure_and_run}
    #   removed.
    def clean_copy
        dup.tap do |j|
            j.remove_resources
            j.skip_states.clear
        end
    end

    # @return   [Job]
    #   Copy of `self`
    def dup
        n = self.class.new( add_id( @options ) )
        n.time = time
        n.skip_states = skip_states.dup
        n.timed_out!( time ) if timed_out?
        n
    end

    # @param    [Hash]  options
    #   See {#initialize}.
    #
    # @return   [Job]
    #   Re-used request (mainly its {#id} and thus its callback as well),
    #   configured with the given `options`.
    def forward( options = {} )
        self.class.new forward_options( options )
    end

    # @param    [Job]  job_type
    #   Job class under {Jobs}.
    # @param    [Hash]  options
    #   Initialization options for `job_type`.
    #
    # @return   [Job]
    #   Forwarded request (preserving its {#id} and thus its callback as well),
    #   configured with the given `options`.
    def forward_as( job_type, options = {} )
        # Remove the ID because this will be a different class/job type and
        # we thus need to keep track of it separately in the BrowserPool.
        job_type.new (forward_options( options ).tap do |h|
            h.delete :id
            h.delete :skip_states
        end)
    end

    # @return   [Integer]
    #   ID, used by the {BrowserPool}, to tie requests to callbacks.
    def id
        @id
    end

    def hash
        @options.hash
    end

    def ==( other )
        hash == other.hash
    end

    protected

    def remove_resources
        @browser = nil
    end

    private

    def forward_options( options )
        add_id( options ).merge(
            args:         args,
            skip_states:  skip_states,
            category:     category,
            never_ending: never_ending?
        )
    end

    def add_id( options )
        options.merge( id: @id )
    end

    def set_resources( browser )
        @browser = browser
    end

end

end
end
