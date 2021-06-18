=begin
    Copyright 2020 Tasos Laskos <tasos.laskos@gmail.com>

    This file is part of the SCNR::Engine project and is subject to
    redistribution and commercial restrictions. Please see the SCNR::Engine
    web site for more information on licensing and terms of use.
=end

module SCNR::Engine
class Browser
module Parts

module Snapshots
    include Support::Mixins::Observable

    # @!method on_new_page( &block )
    advertise :on_new_page

    # @!method on_new_page_with_sink( &block )
    advertise :on_new_page_with_sink

    # @return   [Support::Filter::Set]
    #   States that have been visited and should be skipped.
    #
    # @see #skip_state
    # @see #skip_state?
    attr_reader :skip_states

    # @return   [ParseProfile]
    attr_accessor :parse_profile

    # @return   [Array<Page::DOM::Transition>]
    attr_reader :transitions

    # @return   [Array<Page>]
    #   Same as {#page_snapshots} but it doesn't deduplicate and only contains
    #   pages with sink ({Page::DOM#data_flow_sinks} or {Page::DOM#execution_flow_sinks})
    #   data as populated by {Javascript#data_flow_sinks} and {Javascript#execution_flow_sinks}.
    #
    # @see Javascript#data_flow_sinks
    # @see Javascript#execution_flow_sinks
    # @see Page::DOM#data_flow_sinks
    # @see Page::DOM#execution_flow_sinks
    attr_reader :page_snapshots_with_sinks

    def initialize
        super

        self.parse_profile = @options[:parse_profile]

        @options[:store_pages] = true if !@options.include?( :store_pages )

        # Captured pages -- populated by #capture.
        @captured_pages = []

        # Snapshots of the working page resulting from firing of events and
        # clicking of JS links.
        @page_snapshots = {}

        # Same as @page_snapshots but it doesn't deduplicate and only contains
        # pages with sink (Page::DOM#sink) data as populated by Javascript#flush_sink.
        @page_snapshots_with_sinks = []

        # Keeps track of resources which should be skipped -- like already fired
        # events and clicked links etc.
        @skip_states = Support::Filter::Set.new(hasher: :persistent_hash )

        @transitions = []
        @request_transitions = []
        @add_request_transitions = true
    end

    def parse_profile=( profile )
        if profile && !profile.is_a?( ParseProfile )
            fail ArgumentError, "Invalid profile: #{p.inspect}"
        end

        @parse_profile = profile || ParseProfile.new
    end

    # Explores the browser's DOM tree and captures page snapshots for each
    # state change until there are no more available.
    #
    # @param    [Integer]   depth
    #   How deep to go into the DOM tree.
    #
    # @return   [Array<Page>]
    #   Page snapshots for each state.
    def explore_and_flush( depth = nil )
        pages         = [ to_page ]
        current_depth = 0

        loop do
            bcnt   = pages.size
            pages |= pages.map { |p| load( p ).trigger_events.flush_pages }.flatten

            break if pages.size == bcnt || (depth && depth >= current_depth)

            current_depth += 1
        end

        pages.compact
    end

    # Starts capturing requests and parses them into elements of pages,
    # accessible via {#captured_pages}.
    #
    # @return   [Browser]
    #   `self`
    #
    # @see #stop_capture
    # @see #capture?
    # @see #captured_pages
    # @see #flush_pages
    def start_capture
        @capture = true
        self
    end

    # Stops the {HTTP::Request} capture.
    #
    # @return   [Browser]
    #   `self`
    #
    # @see #start_capture
    # @see #capture?
    # @see #flush_pages
    def stop_capture
        @capture = false
        self
    end

    # @return   [Bool]
    #   `true` if request capturing is enabled, `false` otherwise.
    #
    # @see #start_capture
    # @see #stop_capture
    def capture?
        !!@capture
    end

    # @return   [Array<Page>]
    #   Page snapshots (stored after events have been fired and JS links clicked)
    #   with hashes as keys and pages as values.
    def page_snapshots
        @page_snapshots.values
    end

    # @return   [Array<Page>]
    #   Captured HTTP requests performed by the web page (AJAX etc.) converted
    #   into forms of pages to assist with analysis and audit.
    def captured_pages
        @captured_pages
    end

    # @return   [Page::DOM]
    def state
        d_url = dom_url

        return if !response

        Page::DOM.new(
            url:         d_url,
            transitions: @transitions.dup,
            digest:      @javascript.dom_digest,
            skip_states: skip_states.dup
        )
    end

    # Make parsing and other fields optional for jobs that don't need to know
    # about the body or sinks or elements etc.
    # This could be what's causing high RAM usage for large pages.
    # Add that stuff in special @profile or something and reset it for each job,
    # as usual. Have a Job#parse_profile that sets the Browser#parse_profile.
    #
    # @return   [Page]
    #   Converts the current browser window to a {Page page}.
    def to_page
        d_url = self.dom_url

        has_data_flow_sink_signal = @has_data_flow_sink_signal
        @has_data_flow_sink_signal = false

        if !(r = self.response)
            return Page.from_data(
                dom: {
                    url: d_url,
                    has_data_flow_sink_signal: has_data_flow_sink_signal
                },
                response: {
                    code: 0,
                    url:  url
                }
            )
        end

        if parse_profile.elements || parse_profile.data_flow_sinks
            # We need sink data for both the current taint and to determine
            # cookie usage, so grab all of the data-flow sinks once.
            data_flow_sinks = {}
            if @javascript.supported?
                data_flow_sinks = @javascript.taint_tracer.data_flow_sinks
            end
        end

        r = r.dup
        javascript.remove_env_from_html!( r.body )

        page                 = r.to_page
        page.dom.url         = d_url
        page.dom.transitions = @transitions.dup

        if has_data_flow_sink_signal
            page.dom.has_data_flow_sink_signal!
        end

        return page if parse_profile.disabled?

        if parse_profile.body
            page.body = source
        end

        if parse_profile.cookies
            page.dom.cookies = self.cookies
        end

        if parse_profile.digest
            page.dom.digest = @javascript.dom_digest
        end

        if parse_profile.execution_flow_sinks
            page.dom.execution_flow_sinks = @javascript.execution_flow_sinks
        end

        if parse_profile.data_flow_sinks
            page.dom.data_flow_sinks =
                data_flow_sinks[@javascript.taint] || []
        end

        # TODO: Go through the stackframes of the traces and verify line
        # numbers with method calls in the page source, fail if they don't match.

        if parse_profile.skip_states
            page.dom.skip_states = skip_states.dup
        end

        return page if !parse_profile.elements

        if Options.audit.ui_inputs?
            page.ui_inputs = Element::UIInput.from_browser( self, page )
        end

        if Options.audit.ui_forms?
            page.ui_forms = Element::UIForm.from_browser( self, page )
        end

        # Go through auditable DOM forms and cookies and remove the DOM from
        # them if no events are associated with it.
        #
        # This can save **A LOT** of time during the audit.
        if @javascript.supported?
            if Options.audit.form_doms?
                page.forms.each do |form|
                    next if !form.node || form.inputs.empty?

                    action = form.node['action'].to_s

                    if action.downcase.start_with?( 'javascript:' )
                        form.skip_dom = false
                        next
                    end

                    # Set skip dom to false temporarily because we need to access
                    # the locator.
                    form.skip_dom = false
                    next if locator_has_events?( form.dom.locator )

                    form.skip_dom = true
                end

                page.update_metadata
            end

            if Options.audit.cookie_doms?
                page.cookies.each do |cookie|
                    next if !(sinks = data_flow_sinks[cookie.name] ||
                        data_flow_sinks[cookie.value])

                    # Don't be satisfied with just a taint match, make sure
                    # the full value is identical.
                    #
                    # For example, if a cookie has '1' as a name or value
                    # that's too generic and can match irrelevant data.
                    #
                    # The current approach isn't perfect of course, but it's
                    # the best we can do.
                    cookie.skip_dom = !sinks.find do |sink|
                        sink.tainted_value == cookie.name ||
                            sink.tainted_value == cookie.value
                    end
                end

                page.update_metadata
            end
        end

        page
    end

    def capture_snapshot( transition = nil )
        pages = []

        request_transitions = flush_request_transitions
        transitions = ([transition] + request_transitions).flatten.compact

        window_handles = selenium.window_handles

        begin
            window_handles.each do |handle|
                if window_handles.size > 1
                    selenium.switch_to.window( handle )
                end

                # We don't even have an HTTP response for the page, don't
                # bother trying anything else.
                next if !response

                unique_id = javascript.dom_event_digest
                already_seen = skip_state?( unique_id )
                skip_state unique_id

                # Avoid a #to_page call if at all possible because it'll generate
                # loads of data.
                if (already_seen && !javascript.has_sinks?) ||
                    self.response.code == 0
                    next
                end

                page = self.to_page

                if pages.empty?
                    transitions.each do |t|
                        @transitions << t
                        page.dom.push_transition t
                    end
                end

                capture_snapshot_with_sink( page )

                if already_seen
                    page.clear_cache
                    next
                end

                # Safegued against pages which generate an inf number of DOM
                # states regardless of UI interactions.
                transition_id ="#{page.dom.url}:#{page.dom.playable_transitions.map(&:hash)}"
                transition_id_seen = skip_state?( transition_id )
                skip_state transition_id
                next page.clear_cache if transition_id_seen

                notify_on_new_page( page )

                if store_pages?
                    @page_snapshots[unique_id] = page
                    pages << page
                end
            end
        rescue Selenium::WebDriver::Error::WebDriverError => e
            print_debug "Could not capture snapshot for: #{@last_url}"

            if transition
                print_debug "-- #{transition}"
            end

            print_debug
            print_debug_exception e
        ensure
            selenium.switch_to.default_content
        end

        pages
    end

    # @return   [Array<Page>]
    #   Returns {#page_snapshots_with_sinks} and flushes it.
    def flush_page_snapshots_with_sinks
        @page_snapshots_with_sinks.dup
    ensure
        @page_snapshots_with_sinks.clear
    end

    # @return   [Array<Page>]
    #   Flushes and returns the {#captured_pages captured} and
    #   {#page_snapshots snapshot} pages.
    #
    # @see #captured_pages
    # @see #page_snapshots
    # @see #start_capture
    # @see #stop_capture
    # @see #capture?
    def flush_pages
        captured_pages + page_snapshots
    ensure
        @captured_pages.clear
        @page_snapshots.clear
    end

    private

    def capture_request( request )
        return if !@last_url || !capture?

        elements = {
            forms: [],
            jsons: [],
            xmls:  []
        }

        found_element = false

        if (json = JSON.from_request( @last_url, request ))
            print_debug_level_2 "Extracted JSON input:\n#{json.source}"

            elements[:jsons] << json
            found_element = true
        end

        if !found_element && (xml = XML.from_request( @last_url, request ))
            print_debug_level_2 "Extracted XML input:\n#{xml.source}"

            elements[:xmls] << xml
            found_element = true
        end

        case request.method
            when :get
                inputs = request.parsed_url.query_parameters
                return if inputs.empty?

                elements[:forms] << Form.new(
                    url:    @last_url,
                    action: request.url,
                    method: request.method,
                    inputs: inputs
                )

            when :post
                inputs = request.parsed_url.query_parameters
                if inputs.any?
                    elements[:forms] << Form.new(
                        url:    @last_url,
                        action: request.url,
                        method: :get,
                        inputs: inputs
                    )
                end

                if !found_element && (inputs = request.body_parameters).any?
                    elements[:forms] << Form.new(
                        url:    @last_url,
                        action: request.url,
                        method: request.method,
                        inputs: inputs
                    )
                end

            else
                return
        end

        el = elements.values.flatten

        if el.empty?
            print_debug_level_2 'No elements found.'
            return
        end

        el.each do |e|
            print_debug_level_2 "Extracted #{e.type} input:\n" <<
                "#{e.method.to_s.upcase} #{e.action} #{e.inputs}"
        end

        # Don't bother if the system in general has already seen the vectors.
        if el.empty? || !el.find { |e| !ElementFilter.include?( e ) }
            print_debug_level_2 'Ignoring, already seen.'
            return
        end

        begin
            if !el.find { |e| !skip_state?( e ) }
                print_debug_level_2 'Ignoring, already seen.'
                return
            end

            el.each { |e| skip_state e.id }
        # This could be an orphaned HTTP request, without a job, if running in
        # BrowserPool::Worker.
        rescue NoMethodError
        end

        page = Page.from_data( elements.merge( url: request.url ) )
        page.response.request = request
        page.dom.push_transition Page::DOM::Transition.new( request.url, :request )

        @captured_pages << page if store_pages?
        notify_on_new_page( page )
    rescue => e
        print_error "Could not capture: #{request.url}"
        print_exception e
        print_debug request.body.to_s
    end

    def locator_has_events?( locator )
        (Javascript.events.flatten.map(&:to_s) & locator.attributes.keys).any? ||
            @javascript.dom_monitor.does_element_have_events( locator.css )
    end

    def store_pages?
        !!@options[:store_pages]
    end

    def capture_snapshot_with_sink( page )
        return if page.dom.data_flow_sinks.empty? &&
            page.dom.execution_flow_sinks.empty?

        notify_on_new_page_with_sink( page )

        return if !store_pages?
        @page_snapshots_with_sinks << page
    end

    def flush_request_transitions
        @request_transitions.dup
    ensure
        @request_transitions.clear
    end

    def skip_state?( state )
        self.skip_states.include? state
    end

    def skip_state( state )
        self.skip_states << state
    end

    def update_skip_states( states )
        self.skip_states.merge states
    end

end
end
end
end
