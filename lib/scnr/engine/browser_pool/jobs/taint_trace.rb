=begin
    Copyright 2020 Tasos Laskos <tasos.laskos@gmail.com>

    This file is part of the SCNR::Engine project and is subject to
    redistribution and commercial restrictions. Please see the SCNR::Engine
    web site for more information on licensing and terms of use.
=end

require_relative 'dom_exploration'

module SCNR::Engine
class BrowserPool
module Jobs

# Traces a {#taint} throughout the JS environment of the given {#resource}.
# It also allows {#injector custom JS code} to be executed under the same scope
# in order to directly introduce the {#taint}.
#
# It will pass each evaluated page with the {TaintTrace::Result result}.
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
class TaintTrace < DOMExploration

    require_relative 'taint_trace/result'
    require_relative 'taint_trace/event_trigger'

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

        browser.load resource, take_snapshot: true
        browser.trigger_events
    end

    def to_s
        "#<#{self.class}:#{object_id} @resource=#{@resource} " <<
            "@taint=#{@taint.inspect} @injector=#{@injector.inspect} " <<
            "time=#{@time} timed_out=#{timed_out?}>"
    end
    alias :inspect :to_s

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
