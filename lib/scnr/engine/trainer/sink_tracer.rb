=begin
    Copyright 2020-2022 Tasos Laskos <tasos.laskos@gmail.com>

    This file is part of the SCNR::Engine project and is subject to
    redistribution and commercial restrictions. Please see the SCNR::Engine
    web site for more information on licensing and terms of use.
=end

module SCNR::Engine
class Trainer

# @author Tasos Laskos <tasos.laskos@gmail.com>
class SinkTracer
    include UI::Output
    personalize_output!

    include Utilities

    def initialize
        # Disable sink tracing, we want maximum audit coverage.
        if Options.audit.high_paranoia?
            Element::DOM::Capabilities::WithSinks::Sinks.enabled.clear
            Element::Capabilities::WithSinks::Sinks.enabled.clear
        end
    end

    def process( page )
        # We want to audit all elements regardless.
        return if Options.audit.high_paranoia?

        page.elements_within_scope.each do |element|
            next if !element.respond_to?( :sinks ) || element.inputs.empty? ||
                element.sinks.traced?

            element = element.dup
            element.auditor = self
            element.sinks.trace
        end
    end

    def skip?(*)
        false
    end

    def http
        HTTP::Client
    end

end

end
end
