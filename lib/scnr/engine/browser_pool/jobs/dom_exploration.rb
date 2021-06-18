=begin
    Copyright 2020 Tasos Laskos <tasos.laskos@gmail.com>

    This file is part of the SCNR::Engine project and is subject to
    redistribution and commercial restrictions. Please see the SCNR::Engine
    web site for more information on licensing and terms of use.
=end

module SCNR::Engine
class BrowserPool
module Jobs

# Loads a {#resource} and {Browser::Parts::Events#trigger_events explores} its DOM.
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
class DOMExploration < Job

    require_relative 'dom_exploration/result'
    require_relative 'dom_exploration/event_trigger'

    # @return [Page::DOM, Page, String, HTTP::Response]
    #   Resource to explore, if given a `String` it will be treated it as a URL
    #   and will be loaded.
    attr_accessor :resource

    def initialize( options )
        self.resource = options.delete(:resource)
        super options
    end

    # Loads a {#resource} and {Browser::Parts::Events#trigger_events explores}
    # its DOM.
    def run
        browser.on_new_page do |page|
            save_result( page: page )

            next if Element::DOM::Capabilities::WithSinks::Sinks.enabled.empty?

            browser.master.queue(
                SinkTrace.new( args: [page] ),
                browser.master.callback_for( self )
            )
        end

        browser.load resource, take_snapshot: true
        browser.trigger_events
    end

    def resource=( r )
        # Pages are heavy objects, better just keep the DOM since the browsers
        # will only load them by it anyways.
        if r.is_a? Page
            @resource = r.dom
            @resource.page = nil
            return r
        end

        @resource = r
    end

    def dup
        super.tap { |j| j.resource = resource }
    end

    def clean_copy
        super.tap { |j| j.resource = nil }
    end

    def to_s
        "#<#{self.class}:#{object_id} @resource=#{@resource} " <<
            "time=#{@time} timed_out=#{timed_out?}>"
    end
    alias :inspect :to_s

end

end
end
end
