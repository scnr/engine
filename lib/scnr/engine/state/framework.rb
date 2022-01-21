=begin
    Copyright 2020-2022 Tasos Laskos <tasos.laskos@gmail.com>

    This file is part of the SCNR::Engine project and is subject to
    redistribution and commercial restrictions. Please see the SCNR::Engine
    web site for more information on licensing and terms of use.
=end

require_relative 'framework/rpc'
require 'forwardable'

module SCNR::Engine
class State

# State information for {SCNR::Engine::Framework}.
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
class Framework
    extend Forwardable
    include Support::Mixins::Observable

    advertise :on_state_change

    attr_accessor :state_machine
    def_delegators :@state_machine,
                   :scanning?, :done?,
                   :running, :running=,  :running?,
                   :status,  :status=,

                   :pause,   :paused,    :pause?,   :paused?,    :pausing?,
                   :resume,  :resumed,   :resume?,  :resumed?,
                   :abort,   :aborted,   :abort?,   :aborted?,   :aborting?,
                   :suspend, :suspended, :suspend?, :suspended?, :suspending?,

                   :timed_out, :timed_out?,

                   :status_messages, :set_status_message, :clear_status_messages,
                   :add_status_message, :available_status_messages

    class StateMachine < Cuboid::State::Application

        # @return   [Hash{Symbol=>String}]
        #   All possible {#status_messages} by type.
        def available_status_messages
            {
              suspending:                       'Will suspend as soon as the current page is audited.',
              waiting_for_browser_pool_jobs: 'Waiting for %i browser cluster jobs to finish.',
              suspending_plugins:               'Suspending plugins.',
              saving_snapshot:                  'Saving snapshot at: %s',
              snapshot_location:                'Snapshot location: %s',
              browser_pool_startup:          'Initialising the browser cluster.',
              browser_pool_shutdown:         'Shutting down the browser cluster.',
              clearing_queues:                  'Clearing the audit queues.',
              waiting_for_plugins:              'Waiting for the plugins to finish.',
              aborting:                         'Aborting the scan.',
              timed_out:                        'Scan timed out.'
            }
        end

        def scanning?
            @status == :scanning
        end

        def timed_out
            @status = :timed_out
            nil
        end

        def timed_out?
            @status == :timed_out
        end
    end

    # {Framework} error namespace.
    #
    # All {Framework} errors inherit from and live under it.
    #
    # @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
    class Error < State::Error
        # @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
        # class StateNotSuspendable < Error
        # end

        StateNotSuspendable  = Cuboid::State::Application::Error::StateNotSuspendable
        StateNotAbortable    = Cuboid::State::Application::Error::StateNotAbortable
        InvalidStatusMessage = Cuboid::State::Application::Error::InvalidStatusMessage
    end

    # @return     [RPC]
    attr_accessor :rpc

    # @return     [Support::Filter::Set]
    attr_reader   :page_queue_filter

    # @return     [Support::Filter::Set]
    attr_reader   :url_queue_filter

    # @return     [Support::Filter::Set]
    attr_reader   :element_pre_check_filter

    # @return     [Support::Filter::Set]
    attr_reader   :page_paths_filter

    # @return     [Support::Filter::Set]
    attr_reader   :dom_analysis_filter

    # @return     [Set]
    attr_reader   :browser_skip_states

    # @return     [Integer]
    attr_accessor :audited_page_count

    def initialize
        super

        @rpc = RPC.new
        @audited_page_count = 0

        @browser_skip_states = Support::Filter::Set.new(hasher: :persistent_hash )

        @page_queue_filter = Support::Filter::Set.new(hasher: :persistent_hash )
        @page_paths_filter = Support::Filter::Set.new(hasher: :paths_hash )
        @dom_analysis_filter = Support::Filter::Set.new(hasher: :playable_transitions_hash )
        @url_queue_filter  = Support::Filter::Set.new(hasher: :persistent_hash )

        @element_pre_check_filter = Support::Filter::Set.new(hasher: :coverage_and_trace_hash )

        @state_machine = StateMachine.new
    end

    def status=( s )
        @state_machine.status = s
        notify_on_state_change self
        s
    end

    def statistics
        {
            rpc:                @rpc.statistics,
            audited_page_count: @audited_page_count,
            browser_states:     @browser_skip_states.size
        }
    end

    # @param    [Page::DOM]  dom
    #
    # @return    [Bool]
    def dom_browser_analyzed?( dom )
        @dom_analysis_filter.include? dom
    end

    # @param    [Page::DOM]  dom
    #   Page to mark as seen.
    def dom_browser_analyzed( dom )
        @dom_analysis_filter << dom
    end

    # @param    [Page]  page
    #
    # @return    [Bool]
    #   `true` if the `page` has already been seen (based on the
    #   {#page_queue_filter}), `false` otherwise.
    #
    # @see #page_seen
    def page_seen?( page )
        @page_queue_filter.include? page
    end

    # @param    [Page]  page
    #   Page to mark as seen.
    #
    # @see #page_seen?
    def page_seen( page )
        @page_queue_filter << page
    end

    # @param    [Page]  page
    #
    # @return    [Bool]
    #   `true` if the `page` has already has had its paths extracted, `false` otherwise.
    #
    # @see #page_paths_seen
    def page_paths_seen?( page )
        @page_paths_filter.include? page
    end

    # @param    [Page]  page
    #   Page to mark as having had its paths extracted.
    #
    # @see #page_paths_seen?
    def page_paths_seen( page )
        @page_paths_filter << page
    end

    # @param    [String]  url
    #
    # @return    [Bool]
    #   `true` if the `url` has already been seen (based on the
    #   {#url_queue_filter}), `false` otherwise.
    #
    # @see #url_seen
    def url_seen?( url )
        @url_queue_filter.include? url
    end

    # @param    [Page]  url
    #   URL to mark as seen.
    #
    # @see #url_seen?
    def url_seen( url )
        @url_queue_filter << url
    end

    # @param    [Support::Filter::Set]  states
    def update_browser_skip_states( states )
        @browser_skip_states.merge states
    end

    # @param    [#coverage_and_trace_hash]  e
    #
    # @return    [Bool]
    #   `true` if the element has already been seen (based on the
    #   {#element_pre_check_filter}), `false` otherwise.
    #
    # @see #element_checked
    def element_checked?( e )
        @element_pre_check_filter.include? e
    end

    # @param    [#coverage_and_trace_hash]  e
    #   Element to mark as seen.
    #
    # @see #element_checked?
    def element_checked( e )
        @element_pre_check_filter << e
    end


    def dump( directory )
        FileUtils.mkdir_p( directory )

        rpc.dump( "#{directory}/rpc/" )

        %w(element_pre_check_filter page_queue_filter url_queue_filter
            browser_skip_states audited_page_count page_paths_filter
            dom_analysis_filter
        ).each do |attribute|
            IO.binwrite( "#{directory}/#{attribute}", Marshal.dump( send(attribute) ) )
        end
    end

    def self.load( directory )
        framework = new

        framework.rpc = RPC.load( "#{directory}/rpc/" )

        %w(element_pre_check_filter page_queue_filter url_queue_filter
            browser_skip_states page_paths_filter dom_analysis_filter
        ).each do |attribute|
            path = "#{directory}/#{attribute}"
            next if !File.exist?( path )

            framework.send(attribute).merge Marshal.load( IO.binread( path ) )
        end

        framework.audited_page_count = Marshal.load( IO.binread( "#{directory}/audited_page_count" ) )
        framework
    end

    def clear
        rpc.clear

        @element_pre_check_filter.clear

        @dom_analysis_filter.clear
        @page_queue_filter.clear
        @page_paths_filter.clear
        @url_queue_filter.clear

        @browser_skip_states.clear
        @audited_page_count = 0

        @state_machine = StateMachine.new
    end

end

end
end
