=begin
    Copyright 2020-2022 Tasos Laskos <tasos.laskos@gmail.com>

    This file is part of the SCNR::Engine Framework project and is subject to
    redistribution and commercial restrictions. Please see the SCNR::Engine Framework
    web site for more information on licensing and terms of use.
=end

module SCNR::Engine

require_relative 'element_filter'
require_relative 'trainer/sink_tracer'

# Trainer class
#
# Analyzes key HTTP responses looking for new auditable elements.
#
# @author Tasos Laskos <tasos.laskos@gmail.com>
class Trainer
    include UI::Output
    include Utilities
    include Support::Mixins::Observable

    # More than 2 results in a lot of GC pressure and higher RAM usage when
    # parsing large pages.
    THREADS   = 2
    MAX_QUEUE = 10

    # @!method on_new_page( &block )
    advertise :on_new_page

    personalize_output!

    MAX_TRAININGS_PER_URL = 25

    # @private
    attr_accessor :framework

    def initialize
        super

        @framework   = Framework
        @sink_tracer = SinkTracer.new
        @updated     = false

        @trainings_per_url = Hash.new( 0 )
    end

    def unhook!
        @unhook = true
    end

    def unhook?
        !!@unhook
    end

    def setup
        return if @setup
        @setup = true

        framework.on_page_audit do |page|
            process page
        end

        HTTP::Client.on_complete do |response|
            next if unhook?
            next if response.request.buffered? || !response.request.train?

            if response.redirect?
                reference_url = @page ? @page.url : Options.url
                redirect_url  = to_absolute( response.headers.location, reference_url )

                HTTP::Client.get( redirect_url ) { |res| push res }
                next
            end

            next if response.request.buffered?

            push response
        end
    end

    def statistics
        {
            worker_count:        thread_pool.length,
            pending_job_count:   thread_pool.queue_length,
            scheduled_job_count: thread_pool.scheduled_task_count,
            completed_job_count: thread_pool.completed_task_count,
            remaining_capacity:  thread_pool.remaining_capacity
        }
    end

    def done?
        thread_pool.scheduled_task_count == thread_pool.completed_task_count
    end

    def wait
        sleep 0.1 while !done?
    end

    # Passes the response on for analysis.
    #
    # If the response contains new elements it creates a new page
    # with those elements and pushes it a buffer.
    #
    # These new pages can then be retrieved by flushing the buffer (#flush).
    #
    # @param  [SCNR::Engine::HTTP::Response]  response
    def push( response )
        if !@page
            print_debug 'No seed page assigned yet.'
            return
        end

        return if !analyze_response?( response )
        @trainings_per_url[response.url] += 1

        thread_pool.post do
            analyze response
        end

        true
    rescue => e
        print_exception e
        nil
    end

    # Sets the current working page and {ElementFilter.update_from_page updates}
    # the {ElementFilter}.
    #
    # @param    [SCNR::Engine::Page]    page
    def process( page )
        @page = page

        ElementFilter.update_from_page page
        @sink_tracer.process @page

        @page
    end

    private

    # Analyzes a response looking for new links, forms and cookies.
    #
    # @param   [HTTP::Response, Page]  resource
    def analyze( resource )
        incoming_page = resource.is_a?( Page ) ? resource : resource.to_page

        print_debug "Started for response with request ID: ##{resource.request.id}"

        has_new_elements = has_new?( incoming_page, :cookies )

        # if the response body is the same as the page body and
        # no new cookies have appeared there's no reason to analyze the page
        if @page && incoming_page.body == @page.body && !has_new_elements &&
            @page.url == incoming_page.url

            incoming_page.clear_cache
            print_debug 'Page hasn\'t changed.'
            return
        end

        [ :forms, :links ].each { |type| has_new_elements ||= has_new?( incoming_page, type ) }

        paths = incoming_page.paths
        synchronize do
            paths.each do |path|
                framework.push_to_url_queue( path )
            end
        end

        if has_new_elements
            synchronize do
                notify_on_new_page incoming_page
                framework.push_to_page_queue( incoming_page )
            end
        else
            incoming_page.clear_cache
        end

        print_debug 'Training complete.'
    end

    def has_new?( incoming_page, element_type )
        count = ElementFilter.send(
            "update_#{element_type}".to_sym,
            incoming_page.send( element_type )
        )

        return if count == 0

        print_info "Found #{count} new #{element_type}."
        true
    end

    def within_scope?( response )
        skip_message = nil
        if @trainings_per_url[response.url] >= MAX_TRAININGS_PER_URL
            skip_message = "Reached maximum trainings (#{MAX_TRAININGS_PER_URL})"
        elsif response.scope.redundant?
            skip_message = 'Matched redundancy filters'
        elsif response.scope.out?
            skip_message = 'Matched exclusion criteria'
        end

        if skip_message
            print_verbose "#{skip_message}, skipping: #{response.url}"
            return false
        end

        true
    end

    def analyze_response?( response )
        if !framework.accepts_more_pages?
            print_info 'No more pages accepted, skipping analysis.'
            return
        end

        return false if !within_scope?( response )

        param_names = response.parsed_url.query_parameters.keys
        cookies     = Cookie.from_headers( response.url, response.headers ).map(&:name)

        k = "#{param_names.hash}:#{cookies.hash}:#{response.body}"

        # Naive optimization but it works a lot of the time. :)
        if state.response_seen? k
            print_debug "Already seen response for request ID: ##{response.request.id}"
            return
        end
        state.response_seen k

        return false if !response.text?

        true
    end

    def state
        State.trainer
    end

    def thread_pool
        # Start a pool that:
        #
        # * Has no workers by default;
        # * Can reach up to THREADS workers max;
        # * Once jobs exceed MAX_QUEUE, new jobs will run in the caller thread,
        #   instead of being rejected or letting the queue grow without bounds.
        @thread_pool ||= Concurrent::ThreadPoolExecutor.new(
            min_threads:     0,
            max_threads:     THREADS,
            max_queue:       MAX_QUEUE,
            fallback_policy: :caller_runs
        )
    end

end
end
