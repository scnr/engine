=begin
    Copyright 2020 Alex Douckas <alexdouckas@gmail.com>, Tasos Laskos <tasos.laskos@gmail.com>

    This file is part of the SCNR::Engine project and is subject to
    redistribution and commercial restrictions. Please see the SCNR::Engine
    web site for more information on licensing and terms of use.
=end

module SCNR::Engine
module Element::Capabilities
module WithSinks

# @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
class Sinks

    class Error < Element::Capabilities::Error
        class InvalidSink < Error
        end

        class DuplicateTrace < Error
        end

        class NonMutation < Error
        end
    end

    module Tracers
    end

    class <<self

        def reset
            @tracers    = {}
            @enabled    = Set.new
            @supported  = Set.new
            @max_cost   = 0
            @extra_seed = ''

            unload_tracers
            load_tracers
        end

        def add_to_max_cost( cost )
            @max_cost += cost
        end

        # The maximum allowed cost for the trace operations.
        # If the trace cost is greater than this number it will not be performed.
        def max_cost
            @max_cost
        end

        def acceptable_cost?( trace_cost )
            trace_cost < max_cost
        end

        def enabled
            @enabled
        end

        def enabled?( sinks )
            (enabled & [sinks].flatten).any?
        end

        # Enables tracing of `sink`.
        #
        # @see Check::Manager#[]
        def enable( sink )
            if !supported? sink
                fail Error::InvalidSink, "Unsupported sink: #{sink}"
            end

            enabled << sink
        end

        def enable_all
            supported.each { |sink| enable sink }
        end

        def tracers
            @tracers
        end

        def register_tracer( tracer, name, sinks = nil )
            sinks ||= [name]

            supported.merge sinks

            tracers[name] = [tracer, Set.new( sinks ) ]
        end

        def select_tracer
            select_tracer_for enabled
        end

        def select_tracer_for( sinks )
            tracers.sort_by do |_, (_, provided_sinks)|
                -(provided_sinks & sinks).size
            end.first[1][0]
        end

        def supported?( sink )
            supported.include? sink
        end

        def supported
            @supported
        end

        def tracer_library
            "#{File.dirname( __FILE__ )}/tracers"
        end

        def tracer_namespace
            Sinks::Tracers
        end

        def unload_tracers
            Utilities.remove_constants tracer_namespace
        end

        def load_tracers
            load "#{tracer_library}/base.rb"
            Dir.glob( "#{tracer_library}/*.rb").each { |f| load f }
        end

        # Appends `string` to an extra seed to be used during tracing, usually
        # to trigger behavior that will result in some sort of webapp error.
        #
        # @see Check::Manager#[]
        def add_to_extra_seed( string )
            return extra_seed if extra_seed.include?( string )
            extra_seed << string
        end

        def extra_seed
            @extra_seed
        end

    end
    reset

    def initialize( options )
        @parent = options[:parent]
    end

    def trace
        return if self.class.enabled.empty?

        ensure_single_trace

        tracer_klass = self.class.select_tracer

        tracer = tracer_klass.new( self, @parent )

        if !self.class.acceptable_cost?( tracer.cost )
            @parent.print_debug "Cost too high #{tracer.cost}/#{self.class.max_cost}," <<
                                    " overriding: #{@parent.coverage_id}"

            @parent.each_mutation( tracer.seed ) { |m| m.sinks.override! }
            return false
        end

        @parent.print_status "Running #{tracer_klass.to_s.split( '::' ).last.downcase} " <<
            "analysis against #{@parent.type} with inputs " <<
            "'#{@parent.inputs.keys.join( ', ')}' using #{@parent.method.upcase} " <<
            "for: #{@parent.action}"

        tracer.run

        true
    end

    supported.each do |sink|
        define_method "#{sink}!" do
            if !@parent.mutation?
                fail Error::NonMutation,
                     "Cannot set sinks for non-mutation: #{@parent.coverage_id}"
            end

            state.push( @parent, sink )
            nil
        end

        define_method "#{sink}" do
            state.get( @parent, sink )
        end

        define_method "#{sink}?" do
            state.include?( @parent, sink )
        end
    end

    def per_input
        inputs = {}

        @parent.inputs.keys.each do |input|
            inputs[input] ||= []
            inputs[input] |= self.class.supported.select do |sink|
                get( sink ).include? input
            end.sort
        end

        inputs
    end

    def print_message
        # Let the user know what the deal is.
        @parent.sinks.per_input.each do |input, sinks|
            sinks.delete :traced
            next if sinks.empty?

            sinks = sinks.map { |sink| "#{sink.to_s.gsub( '_' , ' ' )}" }
            @parent.print_info "#{@parent.type.capitalize} input " <<
               "'#{input}' (using #{@parent.method.upcase}) sinks are #{sinks.join( ', ' )} " <<
               "for: #{@parent.action}"
        end
    end

    private

    def get( sink )
        state.get( @parent, sink )
    end

    def state
        State.sink_tracer
    end

    def ensure_single_trace
        return if !self.traced?

        fail Error::DuplicateTrace,
             "Duplicate trace for: #{@parent.coverage_id}"
    end

end

end
end
end
