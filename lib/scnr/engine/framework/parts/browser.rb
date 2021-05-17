=begin
    Copyright 2020 Tasos Laskos <tasos.laskos@gmail.com> 

    This file is part of the SCNR::Engine project and is subject to
    redistribution and commercial restrictions. Please see the SCNR::Engine
    web site for more information on licensing and terms of use.
=end

module SCNR::Engine
class Framework
module Parts

# Provides access to the {BrowserCluster} and relevant helpers.
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
module Browser

    def Browser.handle_browser_page=( handler )
        @handle_browser_page = handler
    end

    def Browser.handle_browser_page( *args )
        @handle_browser_page.call( *args )
    end

    def Browser.apply_dom_metadata=( handler )
        @apply_dom_metadata = handler
    end

    def Browser.apply_dom_metadata( *args )
        @apply_dom_metadata.call( *args )
    end

    def Browser.set_job_to_crawl( job )
        job.category = :crawl
    end

    # @return   [BrowserCluster, nil]
    #   A lazy-loaded browser cluster or `nil` if
    #   {OptionGroups::BrowserCluster#pool_size} or
    #   {OptionGroups::Scope#dom_depth_limit} are 0 or not
    #   {#host_has_browser?}.
    def browser_cluster
        return if !use_browsers?
        return @browser_cluster if @browser_cluster

        # Initialization may take a while so since we lazy load this make sure
        # that only one thread gets to this code at a time.
        synchronize do
            state.set_status_message :browser_cluster_startup

            # We need class-level methods as browser-cluster callbacks so work
            # around that limitation.
            #
            # Obviously this won't work when multiple Frameworks are running
            # in the same process, but you shouldn't do that anyways.
            Browser.handle_browser_page = method(:handle_browser_page )
            @handle_browser_page_cb = Browser.method(:handle_browser_page )

            Browser.apply_dom_metadata = method(:apply_dom_metadata )
            @apply_dom_metadata_cb = Browser.method(:apply_dom_metadata )

            @browser_cluster = BrowserCluster.new(
                pool_size: Options.browser_cluster.pool_size,
                on_pop:    proc do
                    next if !pause?

                    print_debug 'Blocking browser cluster on pop.'
                    wait_if_paused
                end
            ) do
                # The page queue is getting low, give preference to crawl jobs
                # so that the framework doesn't just sit on its ass.
                if page_queue.size < page_queue.max_buffer_size
                    :crawl
                end
            end

            state.clear_status_messages

            @browser_cluster
        end
    end

    def wait_for_browser_cluster?
        @browser_cluster && !browser_cluster.done?
    end

    # @private
    def browser_cluster_job_skip_states
        browser_job.skip_states
    end

    def use_browsers?
        Options.browser_cluster.enabled? && Options.scope.dom_depth_limit > 0
    end

    private

    def shutdown_browser_cluster
        return if !@browser_cluster

        @browser_cluster.shutdown( false )

        @browser_cluster = nil
        @browser_job     = nil
    end

    def browser_job_update_skip_states( states )
        browser_job.skip_states = states
    end

    def handle_browser_page( result, * )
        page = result.is_a?( Page ) ? result : result.page

        synchronize do
            return if !push_to_page_queue page

            print_status "Got new page from the browser-cluster: #{page.dom.url}"
            print_info "DOM depth: #{page.dom.depth} (Limit: #{Options.scope.dom_depth_limit})"

            if page.dom.transitions.any?
                print_info '  Transitions:'
                page.dom.print_transitions( method(:print_info), '    ' )
            end
        end
    end

    # Passes the `page` to {BrowserCluster#queue} and then pushes
    # the resulting pages to {#push_to_page_queue}.
    #
    # @param    [Page]  page
    #   Page to analyze.
    def perform_browser_analysis( page )
        return if !browser_cluster || !accepts_more_pages? ||
            Options.scope.dom_depth_limit.to_i < page.dom.depth + 1 ||
            !page.has_script?

        # This is meant to deduplicate pages, mostly to avoid re-analyzing
        # pages due to Page#element_sink_trace_hash changes.
        # Don't get fooled by different pages with empty DOMs.
        if page.dom.transitions.any?
            return if state.dom_browser_analyzed? page.dom
            state.dom_browser_analyzed page.dom
        end

        # We need to schedule a separate job for applying metadata because it
        # needs to have a clean state.
        schedule_dom_metadata_application( page )

        browser_cluster.queue(
            browser_job.forward( resource: page.dom.state ),
            @handle_browser_page_cb
        )

        true
    end

    def schedule_dom_metadata_application( page )
        return if page.dom.depth > 0
        return if page.metadata.map { |_, data| data['skip_dom'].values }.
            flatten.compact.any?

        # This optimization only affects Form & Cookie DOM elements,
        # so don't bother if none of the checks are interested in them.
        return if !checks.values.
            find { |c| c.check? page, [Element::Form::DOM, Element::Cookie::DOM], true }

        dom = page.dom.state
        dom.page = nil # Help out the GC.

        @tap ||= Browser.method(:set_job_to_crawl)
        browser_cluster.with_browser_and_tap @tap, dom, @apply_dom_metadata_cb
    end

    def apply_dom_metadata( browser, dom )
        bp = nil

        begin
            browser.parse_profile = SCNR::Engine::Browser::ParseProfile.except(
                :execution_flow_sinks, :data_flow_sinks
            )
            bp = browser.load( dom ).to_page
        rescue Selenium::WebDriver::Error::WebDriverError,
            Watir::Exception::Error => e
            print_debug "Could not apply metadata to '#{dom.url}'" <<
                            " because: #{e} [#{e.class}"
            return
        end

        # Request timeout or some other failure...
        return if bp.code == 0

        browser_cluster.queue(
            BrowserCluster::Jobs::SinkTrace.new( args: [bp] ),
            @handle_browser_page_cb
        )
    end

    def browser_job
        # We'll recycle the same job since all of them will have the same
        # callback. This will force the BrowserCluster to use the same block
        # for all queued jobs.
        #
        # Also, this job should never end so that all analysis operations
        # share the same state.
        @browser_job ||= BrowserCluster::Jobs::DOMExploration.new(
            parse_profile: SCNR::Engine::Browser::ParseProfile.except(
                :execution_flow_sinks, :data_flow_sinks
            ),
            category:      :crawl,
            never_ending:  true
        )
    end

end

end
end
end
