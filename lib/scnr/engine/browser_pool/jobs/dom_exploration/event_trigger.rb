=begin
    Copyright 2020-2022 Tasos Laskos <tasos.laskos@gmail.com>

    This file is part of the SCNR::Engine project and is subject to
    redistribution and commercial restrictions. Please see the SCNR::Engine
    web site for more information on licensing and terms of use.
=end

module SCNR::Engine
class BrowserPool
module Jobs
class DOMExploration

# Loads a {#resource} and {Browser::Parts::Events#trigger_event triggers} the
# specified {#event} on the given {#element element}.
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
class EventTrigger < DOMExploration

    require_relative 'event_trigger/result'

    # @return   [Symbol]
    #   Event to trigger on the given {#element element}.
    attr_accessor :event

    # @return   [Browser::ElementLocator]
    attr_accessor :element

    # Loads a {#resource} and {Browser::Parts::Events#trigger_event triggers}
    # the specified {#event} on the given {#element element}.
    def run
        browser.on_new_page do |page|
            save_result( page: page )

            next if Element::DOM::Capabilities::WithSinks::Sinks.enabled.empty?

            browser.master.queue(
                SinkTrace.new( args: [page] ),
                browser.master.callback_for( self )
            )
        end

        browser.load resource

        # We're disabling page restoration for the trigger as this is an one-time
        # job situation, the browser's state is going to be discarded at the end.
        browser.trigger_event( resource, element, event, false )
    end

    def to_s
        super << " #{@event} #{@element}"
    end

    def inspect
        "#<#{self.class}:#{object_id} @resource=#{@resource} " +
            "@event=#{@event.inspect} @element=#{@element.inspect} " <<
            "time=#{@time} timed_out=#{timed_out?}>"
    end

end

end
end
end
end
