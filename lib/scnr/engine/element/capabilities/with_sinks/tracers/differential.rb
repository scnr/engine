=begin
    Copyright 2020 Tasos Laskos <tasos.laskos@gmail.com>

    This file is part of the SCNR::Engine project and is subject to
    redistribution and commercial restrictions. Please see the SCNR::Engine
    web site for more information on licensing and terms of use.
=end

module SCNR::Engine
module Element::Capabilities
module WithSinks
class Sinks
module Tracers

class Differential < Base

    PRECISION = 2

    OPTIONS = {
        # Only applies to forms and we don't need it because we manually do
        # that for all elements in order to grab the default signature.
        skip_original: true,

        # Allow redundant audits, we need to collect multiple samples to get an
        # accurate signature.
        #
        # Deduplication should be handled by the caller.
        redundant:     true,

        # Don't print audit messages, we'll handle that ourselves.
        silent:        true
    }

    def cost
        cost = 0

        [seed, @sinks.class.extra_seed].each do |s|
            next if s.empty?

            cost += 1
            cost += Auditable.calculate_cost(
                [seed, @sinks.class.extra_seed].reject(&:empty?).size, OPTIONS
            )
        end

        cost * PRECISION
    end

    def run
        mutations = {}
        defaults  = []

        gathered_defaults  = 0
        gathered_responses = 0
        expected_responses = 0

        PRECISION.times do |i|
            expected_responses += 1

            [seed, @sinks.class.extra_seed].each do |s|
                next if s.empty?
                @element.each_mutation( s, OPTIONS ) { expected_responses += 1 }
            end
        end

        PRECISION.times do |i|
            audit_options = OPTIONS

            # Only train from the responses the first time, after that the only
            # difference will be in the noise.
            if i == 0
                audit_options = audit_options.merge( submit: { train: true } )
            end

            # Get the default signature and train during the first request.
            @element.submit( audit_options[:submit] || {} ) do |response|
                defaults << response.body.signature

                gathered_defaults  += 1
                gathered_responses += 1

                if PRECISION == gathered_defaults
                    @element.print_status "Got default signature for #{@element.type} " <<
                        "with inputs #{@element.inputs.keys.join( ', ' )} " <<
                        "pointing to: #{@element.action}"
                end

                next if expected_responses != gathered_responses

                process( defaults, mutations )
            end

            audits = [
                [seed, audit_options]
            ]

            if !@sinks.class.extra_seed.empty?
                audits << ["#{seed}_#{@sinks.class.extra_seed}", OPTIONS]
            end

            audits.each do |args|
                # Get signatures for random probes.
                @element.audit( *args ) do |response, mutation|

                    # Don't analyze the sample values, but we still need to
                    # submit them for the training.
                    if mutation.is_a?( Form ) && mutation.mutation_with_sample_values?
                        gathered_responses += 1
                        next
                    end

                    k = mutation.mutable_hash
                    mutations[k] ||= {
                        mutation:   mutation,
                        signatures: [],
                        counter:    0
                    }

                    # This check doesn't cost much so run it every time for good
                    # measure.
                    find_reflected_sinks( seed, mutation, response )

                    mutations[k][:signatures] << response.body.signature
                    mutations[k][:counter]    += 1

                    gathered_responses  += 1

                    if mutations[k][:counter] == PRECISION
                        @element.print_status "Got signatures for #{mutation.type} input " <<
                            "'#{mutation.affected_input_name}' pointing to: " <<
                            mutation.action
                    end

                    next if expected_responses != gathered_responses

                    process( defaults, mutations )
                end
            end
        end
    end

    private

    def find_reflected_sinks( seed, mutation, response )
        @sinks.class.tracers[:fuzz][0].find_sinks( seed, mutation, response )
    end

    def process( defaults, mutations )
        default = Support::Signature.refine( defaults )

        mutations.values.each do |data|
            data[:mutation].sinks.traced!

            # The input doesn't affect the page at all, mark it as blind so
            # that it'll at least be checked by timing attacks and the like.
            if default == Support::Signature.refine( data[:signatures] )
                data[:mutation].sinks.blind!

            # The page changes when the input's value changes, mark it as
            # active.
            else
                data[:mutation].sinks.active!
            end
        end

        @sinks.print_message
    end

    Sinks.register_tracer self, :differential, [:active, :body, :header_name, :header_value]
end

end
end
end
end
end
