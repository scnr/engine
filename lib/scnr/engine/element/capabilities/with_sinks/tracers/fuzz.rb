=begin
    Copyright 2024 Ecsypno Single Member P.C.

    This file is part of the SCNR::Engine project and is subject to
    redistribution and commercial restrictions. Please see the SCNR::Engine
    web site for more information on licensing and terms of use.
=end

module SCNR::Engine
module Element::Capabilities
module WithSinks
class Sinks
module Tracers

class Fuzz < Base

    class <<self
        include Support::Mixins::Observable
        advertise :on_sinks
    end
    observe!

    OPTIONS = {
        # Don't print audit messages, we'll handle that ourselves.
        silent: true
    }

    def cost
        Auditable.calculate_cost(
            [seed, @sinks.class.extra_seed].flatten.reject(&:empty?).size, OPTIONS
        )
    end

    def run
        gathered_responses = 0
        expected_responses = 0
        @element.each_mutation( [seed, @sinks.class.extra_seed].reject(&:empty?), OPTIONS ) { expected_responses += 1 }

        audits = [
            [seed, OPTIONS]
        ]

        if !@sinks.class.extra_seed.empty?
            audits << ["#{seed}_#{@sinks.class.extra_seed}", OPTIONS]
        end

        audits.each do |args|
            @element.audit( *args ) do |response, mutation|
                process( seed, mutation, response )

                gathered_responses += 1
                next if expected_responses != gathered_responses

                @sinks.print_message
            end
        end
    end

    def self.find_sinks( seed, mutation, response )
        r = /#{seed}/i
        found = false

        if r.match? response.body
            mutation.sinks.body!

            found = true
        end

        response.headers.each do |k, v|
            if r.match? k
                mutation.sinks.header_name!
                found = true
            end

            if v.is_a?( String ) && r.match?( v )
                mutation.sinks.header_value!
                found = true
            elsif v.is_a? Array
                v.each do |hv|
                    if r.match? hv
                        mutation.sinks.header_value!
                        found = true
                    end
                end
            end
        end

        if found
            self.notify_on_sinks seed, mutation, response
        end
    end

    private

    def process( seed, mutation, response )
        self.class.find_sinks( seed, mutation, response )
        mutation.sinks.traced!
    end

    Sinks.register_tracer self, :fuzz, [:body, :header_name, :header_value]
end

end
end
end
end
end
