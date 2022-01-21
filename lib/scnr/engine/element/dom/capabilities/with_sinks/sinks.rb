=begin
    Copyright 2020-2022 Tasos Laskos <tasos.laskos@gmail.com>

    This file is part of the SCNR::Engine project and is subject to
    redistribution and commercial restrictions. Please see the SCNR::Engine
    web site for more information on licensing and terms of use.
=end

module SCNR::Engine
module Element::DOM::Capabilities
module WithSinks

# @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
class Sinks < Element::Capabilities::WithSinks::Sinks

    module Tracers
    end

    class <<self
        def reset
            super

            @mutex  = Mutex.new
            @claims = Set.new
        end

        def claims
            @claims
        end

        def claim( element )
            # Some other thread got to this element first, let it have it.
            return false if claimed? element

            synchronize do
                claims << element.coverage_hash
                true
            end
        end

        def claimed?( element )
            synchronize do
                claims.include? element.coverage_hash
            end
        end

        def unclaim( element )
            synchronize do
                claims.delete element.coverage_hash
            end
        end

        def tracer_namespace
            Sinks::Tracers
        end

        def tracer_library
            "#{File.dirname( __FILE__ )}/tracers"
        end

        private

        def synchronize( &block )
            @mutex.synchronize( &block )
        end
    end
    reset

    def trace
        claim { super }
    end

    def tracing?
        claimed?
    end

    private

    def claimed?
        self.class.claimed? @parent
    end

    def claim( &block )
        return if !self.class.claim( @parent )

        begin
            block.call
        rescue
            raise
        ensure
            self.class.unclaim @parent
        end
    end

end

end
end
end
