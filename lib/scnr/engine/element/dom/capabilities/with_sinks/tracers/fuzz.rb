=begin
    Copyright 2020 Alex Douckas <alexdouckas@gmail.com>, Tasos Laskos <tasos.laskos@gmail.com>

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

        mutation.sinks.traced!

        # One of the occurrences will be the actual setting of the taint.
        if /#{seed}/i.match? page.body
            mutation.sinks.active!
            mutation.sinks.body!

            mutation.sinks.print_message
            return
        end

        if page.dom.data_flow_sinks.any?
            mutation.sinks.active!

            mutation.sinks.print_message
            return
        end

        mutation.sinks.blind!

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
