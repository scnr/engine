=begin
    Copyright 2020 Tasos Laskos <tasos.laskos@gmail.com>

    This file is part of the SCNR::Engine project and is subject to
    redistribution and commercial restrictions. Please see the SCNR::Engine
    web site for more information on licensing and terms of use.
=end

require_relative '../../selenium/webdriver/element'
require_relative '../element_locator'

module SCNR::Engine
class Browser
module Parts

module Events
    include Support::Mixins::Observable

    class <<self
        include Support::Mixins::Observable
        advertise :before_event
        advertise :on_event
        advertise :after_event

        include Support::Mixins::Decisions
        query :select
        query :reject
    end
    observe!
    ask!

    # How much time to wait for a targeted HTML element to appear on the page
    # after the page is loaded.
    ELEMENT_APPEARANCE_TIMEOUT = 5

    INPUT_EVENTS          = Set.new([
        :change, :blur, :focus, :select, :keyup, :keypress, :keydown, :input
    ])

    # @note Will skip non-visible elements as they can't be manipulated.
    #
    # Iterates over all elements which have events and passes their info to the
    # given block.
    #
    # @yield    [ElementLocator,Array<Symbol>]
    #   Element locator along with the element's applicable events along with
    #   their handlers and attributes.
    def each_element_with_events( whitelist = [])
        current_url = self.url

        javascript.each_dom_element_with_events whitelist do |element|
            tag_name   = element['tag_name'].freeze
            attributes = element['attributes']
            events     = element['events']

            case tag_name
                when 'a'
                    href = attributes['href'].to_s

                    if !href.empty?
                        if href.downcase.start_with?( 'javascript:' )
                            (events[:click] ||= []) << href
                        else
                            next if skip_path?( to_absolute( href, current_url ) )
                        end
                    end

                when 'input'
                    if attributes['type'].to_s.downcase == 'image'
                        (events[:click] ||= []) << 'image'
                    end

                when 'form'
                    action = attributes['action'].to_s

                    if !action.empty?
                        if action.downcase.start_with?( 'javascript:' )
                            (events[:submit] ||= []) << action
                        else
                            next if skip_path?( to_absolute( action, current_url ) )
                        end
                    end
            end

            next if events.empty?

            yield ElementLocator.new( tag_name: tag_name, attributes: attributes ),
                events
        end

        self
    end

    # Triggers all events on all elements (**once**) and captures
    # {Snapshots#page_snapshots page snapshots}.
    #
    # @return   [Browser]
    #   `self`
    def trigger_events
        dom = self.state
        return self if !dom

        url = normalize_url( dom.url )

        count = 1
        each_element_with_events do |locator, events|
            state = "#{url}:#{locator.tag_name}:#{locator.attributes}:#{events.keys.sort}"
            next if skip_state?( state )
            skip_state state

            events.each do |name, _|
                if Options.scope.dom_event_limit_reached?( count )
                    print_debug "DOM event limit reached for: #{dom.url}"
                    return self
                end

                distribute_event( dom, locator, name.to_sym )

                count += 1
            end
        end

        self
    end

    # @note Only used when running as part of {BrowserPool} to distribute
    #   page analysis across a pool of browsers.
    #
    # Distributes the triggering of `event` on the element at `element_index`
    # on `page`.
    #
    # @param    [String, Page, Page::DOM, HTTP::Response]    resource
    # @param    [ElementLocator]  locator
    # @param    [Symbol]  event
    def distribute_event( resource, locator, event )
        trigger_event( resource, locator, event )
    end

    # @note Captures page {Snapshots#page_snapshots}.
    #
    # Triggers `event` on the element described by `tag` on `page`.
    #
    # @param    [String, Page, Page::DOM, HTTP::Response]    resource
    #   Page containing the element's `tag`.
    # @param    [ElementLocator]  element
    # @param    [Symbol]  event
    #   Event to trigger.
    def trigger_event( resource, element, event, restore = true )
        transition = fire_event( element, event )

        if !transition
            print_debug "Could not trigger '#{event}' on: #{element}"

            if restore
                print_debug 'Restoring page.'
                restore( resource )
            end

            return
        end

        capture_snapshot( transition )
        restore( resource ) if restore
    end

    # Triggers `event` on `element`.
    #
    # @param    [ElementLocator]  locator
    # @param    [Symbol]  event
    # @param    [Hash]  options
    # @option options [Hash<Symbol,String=>String>]  :inputs
    #   Values to use to fill-in inputs. Keys should be input names or ids.
    #
    #   Defaults to using {OptionGroups::Input} if not specified.
    #
    # @return   [Page::DOM::Transition, false]
    #   Transition if the operation was successful, `nil` otherwise.
    def fire_event( locator, event, options = {} )
        event       = event.to_s.downcase.sub( /^on/, '' ).to_sym
        opening_tag = locator.to_s
        tag_name    = locator.tag_name.to_s

        options[:inputs] = options[:inputs].my_stringify if options[:inputs]

        return if Events.reject?( locator, event, options, self )
        return if Events.ask_select? && !Events.select?( locator, event, options, self )

        Events.notify_before_event locator, event, options, self

        # Only forms will have inputs, for any other element the call will
        # return an empty array, if however the element does not even exist
        # it will return false so we can both get info we can possibly use
        # later on and check for element existence with only 1 selenium call.
        inputs = @javascript.dom_monitor.element_input_names( locator.css )
        if !inputs
            print_debug "Element '#{locator}' could not be located for triggering '#{event}'."
            return
        end

        print_debug_level_2 "[start]: #{event} (#{options}) #{locator}"

        begin
            transition = Page::DOM::Transition.new( locator, event, options ) do

                if tag_name == 'form' && !options[:inputs]
                    options[:inputs] = {}
                    inputs.each do |name|
                        options[:inputs][name] = value_for_name( name )
                    end
                elsif INPUT_EVENTS.include?( event ) && !options[:value]
                    options[:value] = value_for( locator )
                end

                r = @javascript.events.fire( tag_name, locator.css, event, options )
                Events.notify_on_event( r, locator, event, options, self )
                fail Selenium::WebDriver::Error::WebDriverError, 'Event fire failed.' if !r

                print_debug_level_2 "[waiting for requests]: #{event} (#{options}) #{locator}"
                engine.wait_for_pending_requests
                print_debug_level_2 "[done waiting for requests]: #{event} (#{options}) #{locator}"

                # Maybe we switched to a different page, wait until the custom
                # JS env has been put in place.
                javascript.wait_till_ready
                javascript.set_element_ids

                update_cookies
            end

            print_debug_level_2 "[done in #{transition.time}s]: #{event} (#{options}) #{locator}"

            Events.notify_after_event transition, locator, event, options, self
            transition
        rescue Selenium::WebDriver::Error::WebDriverError => e

            print_debug "Error when triggering event for: #{dom_url}"
            print_debug "-- '#{event}' on: #{opening_tag} -- #{locator.css}"
            print_debug
            print_debug_exception e
            nil
        end
    end

    private

    # @param    [ElementLocator]    locator
    # @return   [String]
    #   Value to use to fill-in the input.
    #
    # @see OptionGroups::Input.value_for_name
    def value_for( locator )
        Options.input.value_for_name( name_or_id_for( locator ) )
    end

    def value_for_name( name )
        Options.input.value_for_name( name )
    end

    def name_or_id_for( locator )
        name = locator.attributes['name'].to_s
        return name if !name.empty?

        id = locator.attributes['id'].to_s
        return id if !id.empty?

        nil
    end

    # Loads `page` without taking a snapshot, used for restoring  the root page
    # after manipulation.
    def restore( page )
        load page
    end

end
end
end
end
