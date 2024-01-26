=begin
    Copyright 2024 Ecsypno Single Member P.C.

    This file is part of the SCNR::Engine project and is subject to
    redistribution and commercial restrictions. Please see the SCNR::Engine
    web site for more information on licensing and terms of use.
=end

module SCNR::Engine
module Element::DOM::Capabilities
module WithSinks
class Sinks
module Tracers

class Fuzz < Base
    include Component::Output
    extend Component::Output

    class <<self
        include Support::Mixins::Observable
        advertise :on_sinks
    end
    observe!

    OPTIONS = {
        format: [ Element::Capabilities::Mutable::Format::APPEND ],
        silent: true
    }

    def self.parse_profile
        @parse_profile ||= Browser::ParseProfile.only( :body, :data_flow_sinks )
    end

    def cost
        Element::Capabilities::Auditable.calculate_cost( 1, OPTIONS )
    end

    def run
        options = OPTIONS.merge(
            submit: {
                taint:   seed,
                browser: {
                    parse_profile: self.class.parse_profile
                }
            }
        )

        @auditor = @element.auditor
        @element.auditor = self
        @element.audit( seed, options )
    end

    def skip?(*)
    end

    def with_browser( *args )
        @auditor.with_browser( *args )
    end

    def self.check_and_log( page, mutation )
        seed = mutation.seed

        found = false
        # One of the occurrences will be the actual setting of the taint.
        if /#{seed}/i.match? page.body
            mutation.sinks.body!
            found = true

            mutation.sinks.print_message
        end

        ## TODO: Add tests for signals
        if page.dom.has_data_flow_sink_signal? || page.dom.data_flow_sinks.any?
            mutation.sinks.active!
            found = true

            mutation.sinks.print_message
        end

        if found
            self.notify_on_sinks seed, mutation, page
        else
            mutation.sinks.blind!
        end
        mutation.sinks.traced!

        mutation.sinks.print_message
    end

    def self.fullname
        'DOMSinkTracer'
    end

    Sinks.register_tracer self, :fuzz, [:body, :active]
end

end
end
end
end
end
