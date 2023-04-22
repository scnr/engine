=begin
    Copyright 2020-2022 Tasos Laskos <tasos.laskos@gmail.com>

    This file is part of the SCNR::Engine project and is subject to
    redistribution and commercial restrictions. Please see the SCNR::Engine
    web site for more information on licensing and terms of use.
=end

module SCNR::Engine
class Framework
module Parts

# Provides access to the {BrowserPool} and relevant helpers.
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
module Browser

    class <<self

        def synchronize( &block )
            (@mutex ||= Mutex.new).synchronize( &block )
        end

        def handle_browser_page( result, * )
            synchronize do
                Parts::Data.push_to_page_queue(
                  result.is_a?( Page ) ? result : result.page
                )
            end
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

            # Go over everything, don't try a trace.
            if !Options.audit.super_mode?
                Framework.browser_pool.queue(
                  BrowserPool::Jobs::SinkTrace.new( args: [bp] ),
                  method(:handle_browser_page)
                )
            end
        end

        def set_job_to_crawl( job )
            job.category = :crawl
        end

    end
    Browser.synchronize {}

    # @return   [BrowserPool, nil]
    #   A lazy-loaded browser cluster or `nil` if
    #   {OptionGroups::DOM#size} or
    #   {OptionGroups::Scope#dom_depth_limit} are 0 or not
    #   {#host_has_browser?}.
    def browser_pool
        return if !use_browsers?
        return @browser_pool if @browser_pool

        # Initialization may take a while so since we lazy load this make sure
        # that only one thread gets to this code at a time.
        synchronize do
            state.set_status_message :browser_pool_startup

            @browser_pool = BrowserPool.new(
                size: Options.dom.pool_size,
                on_pop:    proc do
                    next if !pause?

                    print_debug 'Blocking browser cluster on pop.'
                    wait_if_paused
                end
            ) do
                # The page queue is getting low, give preference to crawl jobs
                # so that the framework doesn't just sit on its ass.
                if page_queue.size < page_queue.max_buffer_size * 5
                    :crawl
                end
            end

            state.clear_status_messages

            @browser_pool
        end
    end

    def wait_for_browser_pool?
        @browser_pool && !browser_pool.done?
    end

    def use_browsers?
        Options.dom.enabled? && Options.scope.dom_depth_limit > 0
    end

    private

    def shutdown_browser_pool
        return if !@browser_pool

        @browser_pool.shutdown( false )

        @browser_pool = nil
        @browser_job     = nil
    end

    # Passes the `page` to {BrowserPool#queue} and then pushes
    # the resulting pages to {#push_to_page_queue}.
    #
    # @param    [Page]  page
    #   Page to analyze.
    def perform_browser_analysis( page )
        return if !browser_pool || !accepts_more_pages? ||
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

        browser_pool.queue(
            browser_job.forward( resource: page.dom.state ),
            Browser.method(:handle_browser_page)
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
        browser_pool.with_browser_and_tap @tap, dom, Browser.method(:apply_dom_metadata )
    end

    def browser_job
        # We'll recycle the same job since all of them will have the same
        # callback. This will force the BrowserPool to use the same block
        # for all queued jobs.
        #
        # Also, this job should never end so that all analysis operations
        # share the same state.
        @browser_job ||= BrowserPool::Jobs::DOMExploration.new(
            parse_profile: SCNR::Engine::Browser::ParseProfile.except(
                :execution_flow_sinks, :data_flow_sinks
            ),
            # Special and constant ID in order to maintain states when
            # suspending/restoring.
            id:            Float::INFINITY,
            category:      :crawl,
            never_ending:  true
        )
    end

end

end
end
end
