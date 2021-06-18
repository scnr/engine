=begin
    Copyright 2020 Alex Douckas <alexdouckas@gmail.com>, Tasos Laskos <tasos.laskos@gmail.com>

    This file is part of the SCNR::Engine project and is subject to
    redistribution and commercial restrictions. Please see the SCNR::Engine
    web site for more information on licensing and terms of use.
=end

module SCNR::Engine
class BrowserPool
module Jobs
class TaintTrace

# @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
class EventTrigger < DOMExploration::EventTrigger

    require_relative 'event_trigger/result'

    # @return [String]
    #   Taint to trace throughout the data-flow of the JS environment.
    attr_accessor :taint

    # @return [String]
    #   JS code to execute in order to introduce the taint.
    attr_accessor :injector

    def run
        browser.javascript.taint       = self.taint
        browser.javascript.custom_code = self.injector

        browser.on_new_page_with_sink { |page| save_result( page: page ) }

        browser.load resource

        # We're disabling page restoration for the trigger as this is an one-time
        # job situation, the browser's state is going to be discarded at the end.
        browser.trigger_event( resource, element, event, false )
    end

    def to_s
        "#<#{self.class}:#{object_id} @resource=#{@resource} " +
          "@taint=#{@taint.inspect} @injector=#{@injector.inspect} " +
            "@event=#{@event.inspect} @element=#{@element.inspect} " +
            "time=#{@time} timed_out=#{timed_out?}>"
    end

    private

    def forward_options( options )
        super.merge(
          taint:    taint,
          injector: injector
        )
    end
end

end
end
end
end
