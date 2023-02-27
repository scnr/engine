=begin
    Copyright 2020-2022 Tasos Laskos <tasos.laskos@gmail.com>

    This file is part of the SCNR::Engine project and is subject to
    redistribution and commercial restrictions. Please see the SCNR::Engine
    web site for more information on licensing and terms of use.
=end

module SCNR::Engine
class BrowserPool
module Jobs

class SinkTrace < Job

    require_relative 'sink_trace/dom_sink_tracer'

    def initialize(*)
        super

        @category = :crawl
    end

    def run
        page = self.args.first

        page.elements_within_scope.each do |element|
            next if !element.respond_to?( :dom ) || element.skip_dom?

            e = element.dom
            next if !e || e.sinks.tracing? || e.sinks.traced?

            browser.master.queue(
                SinkTrace::DOMSinkTracer.new(
                    page:    page,
                    element: element
                ),
                browser.master.callback_for( self )
            )
        end
    end

    def to_s
        super << " #{self.args.first.url}"
    end

end
end
end
end
