=begin
    Copyright 2020-2022 Tasos Laskos <tasos.laskos@gmail.com>

    This file is part of the SCNR::Engine project and is subject to
    redistribution and commercial restrictions. Please see the SCNR::Engine
    web site for more information on licensing and terms of use.
=end

module SCNR::Engine
class Browser
module Parts

module Navigation

    class <<self
        include Support::Mixins::Observable

        advertise :before_load
        advertise :after_load
    end
    observe!

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

        @add_transitions = true

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
                Navigation.notify_before_load resource, options, self

                @transitions = []
                goto resource, options

                Navigation.notify_after_load resource, options, self

            when SCNR::Engine::HTTP::Response
                Navigation.notify_before_load resource, options, self

                @transitions = []
                goto preload( resource ), options

                Navigation.notify_after_load resource, options, self

            when Page
                SCNR::Engine::HTTP::Client.update_cookies resource.cookie_jar

                load resource.dom

            when Page::DOM
                Navigation.notify_before_load resource, options, self

                @transitions = resource.transitions.dup

                @add_transitions = false if @transitions.any?
                resource.restore *[self, options[:take_snapshot]].compact
                @add_transitions = true

                Navigation.notify_after_load resource, options, self

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

        @last_url = SCNR::Engine::URI( url ).to_s

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

            Options.dom.css_to_wait_for( url ).each do |css|
                print_info "Waiting for #{css.inspect} to appear for: #{url}"

                begin
                    Selenium::WebDriver::Wait.new(
                        timeout: Options.dom.job_timeout
                    ).until do
                        @javascript.dom_monitor.is_visible_selector( css )
                    end

                    print_info "#{css.inspect} appeared for: #{url}"
                rescue Selenium::WebDriver::Error::TimeoutError
                    print_bad "#{css.inspect} did not appear for: #{url}"
                end

            end

            javascript.set_element_ids
        end

        if @add_transitions && update_transitions
            @transitions << transition
        end

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
