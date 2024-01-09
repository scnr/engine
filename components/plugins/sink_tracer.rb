=begin
    Copyright 2024 Tasos Laskos <tasos.laskos@gmail.com>

    This file is part of the SCNR::Engine project and is subject to
    redistribution and commercial restrictions. Please see the SCNR::Engine
    web site for more information on licensing and terms of use.
=end

# @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
# @version 0.1
class SCNR::Engine::Plugins::SinkTracer < SCNR::Engine::Plugin::Base

    def run
        print_info "Setting sink-tracing to always on."
        load_sink_trace_force_check

        @sinks = {}

        Element::Capabilities::WithSinks::Sinks::Tracers::Fuzz.on_sinks do |seed, mutation, resource|
            @sinks[mutation.coverage_and_trace_hash] = prepare_entry( seed, mutation, resource )
        end

        Element::Capabilities::WithSinks::Sinks::Tracers::Differential.on_sinks do |seed, mutation|
            @sinks[mutation.coverage_and_trace_hash] = prepare_entry( seed, mutation )
        end

        Element::DOM::Capabilities::WithSinks::Sinks::Tracers::Fuzz.on_sinks do |seed, mutation, resource|
            @sinks[mutation.coverage_and_trace_hash] = prepare_entry( seed, mutation, resource )
        end

        wait_while_framework_running

        register_results @sinks
    end

    def load_sink_trace_force_check
        Element::Capabilities::WithSinks::Sinks.add_to_max_cost Float::INFINITY
        Element::Capabilities::WithSinks::Sinks.enable_all

        Element::DOM::Capabilities::WithSinks::Sinks.add_to_max_cost Float::INFINITY
        Element::DOM::Capabilities::WithSinks::Sinks.enable_all

        check = Class.new( SCNR::Engine::Check::Base )
        check.shortname = 'sink_trace_force'

        check.define_method :run, &proc {}
        check.define_singleton_method :info, &proc {{
          elements: Check::Auditor::ELEMENTS_WITH_INPUTS,
          sink:     { areas: Element::Capabilities::WithSinks::Sinks.enabled.to_a }
        }}

        framework.checks[check.shortname] = check

        check = Class.new( SCNR::Engine::Check::Base )
        check.shortname = 'sink_trace_force_dom'

        check.define_method :run, &proc {}
        check.define_singleton_method :info, &proc {{
          elements: Check::Auditor::DOM_ELEMENTS_WITH_INPUTS,
          sink:     { areas: Element::DOM::Capabilities::WithSinks::Sinks.enabled.to_a }
        }}

        framework.checks[check.shortname] = check
    end

    def prepare_entry( seed, mutation, resource = nil )
        {
          'seed'     => seed,
          'mutation' => prepare_mutation( mutation ),
          'resource' => resource ? resource.to_rpc_data : nil,
          'sinks'    => prepare_sinks( mutation )
        }
    end

    def prepare_mutation( mutation )
        mutation.dup.tap { |m| m.auditor = nil }.to_rpc_data.merge 'type' => mutation.type
    end

    def prepare_sinks( mutation )
        sinks = {}
        mutation.sinks.per_input.each do |input, s|
            sinks[input] = s.map(&:to_s)
        end
        sinks
    end

    def self.info
        {
          name:        'Sink tracer',
          description: %q{},
          author:      'Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>',
          version:     '0.1'
        }
    end

end
