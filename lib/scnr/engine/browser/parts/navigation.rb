=begin
    Copyright 2020 Alex Douckas <alexdouckas@gmail.com>, Tasos Laskos <tasos.laskos@gmail.com>

    This file is part of the SCNR::Engine project and is subject to
    redistribution and commercial restrictions. Please see the SCNR::Engine
    web site for more information on licensing and terms of use.
=end

module SCNR::Engine
class Browser
module Parts

module Navigation

    class Error < Browser::Error

        # Raised when a given resource can't be loaded.
        #
        # @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
        class Load < Error
        end
    end

    # @return   [Hash]
    #   Preloaded resources, by URL.
    attr_reader :preloads

    attr_reader :last_url

    def initialize
        super

        # User-controlled preloaded responses, by URL.
        @preloads = {}
    end

    # @return   [String]
    #   Current URL, noralized via #{Engine::URI}.
    def url
        normalize_url dom_url
    end

    # @return   [String]
    #   Current URL, as provided by the browser.
    def dom_url
        selenium.current_url
    end

    # @param    [String, HTTP::Response, Page, Page:::DOM]  resource
    #   Loads the given resource in the browser. If it is a string it will be
    #   treated like a URL.
    #
    # @return   [Browser]
    #   `self`
    def load( resource, options = {} )

        case resource
            when String
                @transitions = []
                goto resource, options

            when SCNR::Engine::HTTP::Response
                @transitions = []
                goto preload( resource ), options

            when Page
                SCNR::Engine::HTTP::Client.update_cookies resource.cookie_jar

                load resource.dom

            when Page::DOM
                @transitions = resource.transitions.dup
                update_skip_states resource.skip_states

                @add_request_transitions = false if @transitions.any?
                resource.restore *[self, options[:take_snapshot]].compact
                @add_request_transitions = true

            else
                fail Error::Load,
                     "Can't load resource of type #{resource.class}."
        end

        self
    end

    # @note The preloaded resource will be removed once used.
    #
    # @param    [HTTP::Response, Page]  resource
    #   Preloads a resource to be instantly available by URL via {#load}.
    def preload( resource )
        response =  case resource
                        when SCNR::Engine::HTTP::Response
                            resource

                        when Page
                            resource.response

                        else
                            fail Error::Load,
                                 "Can't preload resource of type #{resource.class}."
                    end

        save_response( response ) if !response.url.include?( request_token )

        @preloads[response.url] = response
        response.url
    end

    # @param    [String]  url
    #   Loads the given URL in the browser.
    # @param    [Hash]  options
    # @option  [Bool]  :take_snapshot  (true)
    #   Take a snapshot right after loading the page.
    # @option  [Array<Cookie>]  :cookies  ([])
    #   Extra cookies to pass to the webapp.
    #
    # @return   [Page::DOM::Transition]
    #   Transition used to replay the resource visit.
    def goto( url, options = {} )
        take_snapshot      = options[:take_snapshot]
        extra_cookies      = options[:cookies] || {}
        update_transitions = options.include?(:update_transitions) ?
            options[:update_transitions] : true

        pre_add_request_transitions = @add_request_transitions
        if !update_transitions
            @add_request_transitions = false
        end

        @last_url = SCNR::Engine::URI( url ).to_s
        self.class.add_asset_domain @last_url

        ensure_open_window

        load_cookies url, extra_cookies

        transition = Page::DOM::Transition.new( :page, :load,
                                                url:     url,
                                                cookies: extra_cookies
        ) do
            print_debug_level_2 "Loading #{url} ..."
            selenium.navigate.to url
            print_debug_level_2 '...done.'

            wait_till_ready

            Options.browser_cluster.css_to_wait_for( url ).each do |css|
                print_info "Waiting for #{css.inspect} to appear for: #{url}"

                begin
                    Selenium::WebDriver::Wait.new(
                        timeout: Options.browser_cluster.job_timeout
                    ).until do
                        @javascript.dom_monitor.is_visible_selector( css )
                    end

                    print_info "#{css.inspect} appeared for: #{url}"
                rescue Selenium::WebDriver::Error::TimeOutError
                    print_bad "#{css.inspect} did not appear for: #{url}"
                end

            end

            javascript.set_element_ids
        end

        if @add_request_transitions
            @transitions << transition
        end

        @add_request_transitions = pre_add_request_transitions

        update_cookies

        # Capture the page at its initial state.
        capture_snapshot if take_snapshot

        transition
    end

    private

    def ensure_open_window
        window_handles = selenium.window_handles

        if window_handles.size == 0
            @javascript.run( 'window.open()' )
            selenium.switch_to.window( selenium.window_handles.last )

        elsif window_handles.size == 1
            selenium.navigate.to 'about:blank'

        # Headless Chrome doesn't like it when iterating over window handles
        # and calling Selenium#close() on them so quit the session and start a
        # new one.
        else
            engine.refresh
        end
    end

end

end
end
end
