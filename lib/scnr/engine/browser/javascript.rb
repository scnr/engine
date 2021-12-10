=begin
    Copyright 2020 Tasos Laskos <tasos.laskos@gmail.com>

    This file is part of the SCNR::Engine project and is subject to
    redistribution and commercial restrictions. Please see the SCNR::Engine
    web site for more information on licensing and terms of use.
=end

module SCNR::Engine
class Browser

# Provides access to the {Browser}'s JavaScript environment, mainly helps
# group and organize functionality related to our custom Javascript interfaces.
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
class Javascript
    include UI::Output
    include Utilities

    require_relative 'javascript/proxy'
    require_relative 'javascript/taint_tracer'
    require_relative 'javascript/dom_monitor'
    require_relative 'javascript/events'

    include Support::Mixins::Parts

    EACH_DOM_ELEMENT_WITH_EVENTS_BATCH_SIZE = 50

    EVENTS = Set.new([
        :onclick,
        :ondblclick,
        :onmousedown,
        :onmousemove,
        :onmouseout,
        :onmouseover,
        :onmouseup,
        :onload,
        :onsubmit,
        :onselect,
        :onchange,
        :onfocus,
        :onblur,
        :onkeydown,
        :onkeypress,
        :onkeyup,
        :oninput,
        :onselect,
        :onchange,
        :onfocus,
        :onblur,
        :onkeydown,
        :onkeypress,
        :onkeyup,
        :oninput,
        :onchange,
        :onfocus,
        :onblur,
        :onfocus,
        :onblur,
        :onfocus,
        :onblur
    ])

    # @return   [DOMMonitor]
    #   {Proxy} for the `DOMMonitor` JS interface.
    attr_reader :dom_monitor

    # @return   [TaintTracer]
    #   {Proxy} for the `TaintTracer` JS interface.
    attr_reader :taint_tracer

    # @return   [Events]
    #   {Proxy} for the `Events` JS interface.
    attr_reader :events

    def self.events
        EVENTS
    end

    # @param    [Browser]   browser
    def initialize( browser )
        @browser      = browser
        @taint_tracer = TaintTracer.new( self )
        @dom_monitor  = DOMMonitor.new( self )
        @events       = Events.new( self )
    end

    # @param    [String]    script
    #   JS code to execute.
    # @param    [Array<Object>] args
    #   Script arguments.
    #
    # @return   [Object]
    #   Result of `script`.
    def run( script, *args )
        @browser.selenium.execute_script( script, *args )
    end

    # Executes the given code but unwraps Watir elements.
    #
    # @param    [String]    script
    #   JS code to execute.
    # @param    [Array<Object>] args
    #   Script arguments.
    #
    # @return   [Object]
    #   Result of `script`.
    def run_without_elements( script, *args )
        unwrap_elements run( script, *args )
    end

    # @note Will not include custom events.
    #
    # @yield   [Hash]
    #   Information about all DOM elements, including any registered event listeners.
    def each_dom_element_with_events( whitelist = [] )
        return if !supported?

        start      = 0
        batch_size = EACH_DOM_ELEMENT_WITH_EVENTS_BATCH_SIZE
        max_events = Options.scope.dom_event_limit

        loop do
            elements = dom_monitor.elements_with_events(
                start,
                batch_size,
                max_events,
                whitelist
            )
            return if elements.empty?

            elements.each do |element|
                events = {}
                element['events'].each do |event, handlers|
                    events[event.to_sym] = handlers
                end
                element['events'] = events

                max_events -= events.size

                yield element

                return if max_events <= 0
            end

            return if elements.size < batch_size

            start += elements.size
        end
    end

    def max_timer
        return if !supported?

        (@dom_monitor.intervals | @dom_monitor.timeouts).compact.
          map { |t| t[1].to_i }.max
    end

    def wait_for_timers
        delay = self.max_timer
        return if !delay

        delay = delay / 1000.0
        print_debug_level_2 "Waiting for max timer #{delay}s..."

        sleep delay

        print_debug_level_2 '...done.'
    end

    private

    def unwrap_elements( obj )
        case obj
            when Watir::Element
                unwrap_element( obj )

            when Selenium::WebDriver::Element
                unwrap_element( obj )

            when Array
                obj.map { |e| unwrap_elements( e ) }

            when Hash
                obj.each { |k, v| obj[k] = unwrap_elements( v ) }
                obj

            else
                obj
        end
    end

    def unwrap_element( element )
        element.html
    rescue Selenium::WebDriver::Error::StaleElementReferenceError
        ''
    end

end
end
end
