=begin
    Copyright 2020 Alex Douckas <alexdouckas@gmail.com>, Tasos Laskos <tasos.laskos@gmail.com>

    This file is part of the SCNR::Engine project and is subject to
    redistribution and commercial restrictions. Please see the SCNR::Engine
    web site for more information on licensing and terms of use.
=end

module SCNR::Engine
class BrowserCluster
module Jobs
class SinkTrace

class DOMSinkTracer < Job
    include UI::Output
    extend  UI::Output
    personalize_output!

    require_relative 'dom_sink_tracer/result'

    attr_accessor :page
    attr_accessor :element

    def initialize(*)
        super

        @category = :crawl
    end

    def run
        return if element.dom.sinks.tracing? || element.dom.sinks.traced?

        e         = element.dom.dup
        e.auditor = self
        e.page    = page

        e.sinks.trace

        p = page.dup
        p.element_sink_trace_hash = e.sink_hash
        save_result( page: p )
    end

    def with_browser( *args )
        cb = args.pop
        cb.call browser, *args
    end

    def skip?(*)
        false
    end

end

end
end
end
end
