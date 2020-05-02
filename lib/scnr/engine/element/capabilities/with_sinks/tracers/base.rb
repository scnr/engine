=begin
    Copyright 2020 Alex Douckas <alexdouckas@gmail.com>, Tasos Laskos <tasos.laskos@gmail.com>

    This file is part of the SCNR::Engine project and is subject to
    redistribution and commercial restrictions. Please see the SCNR::Engine
    web site for more information on licensing and terms of use.
=end

module SCNR::Engine
module Element::Capabilities
module WithSinks
class Sinks
module Tracers

class Base

    def initialize( sinks, element )
        @sinks   = sinks
        @element = element
    end

    def seed
        # Don't use something completely random because when auditing with a
        # parameter flip and Format::APPEND this can lead to an inf loop when
        # training.
        @seed ||= "scnr_engine_sink_tracer_#{Utilities.random_seed}"
    end

    # @abstract
    def cost
        fail 'Not implemented.'
    end

    # @abstract
    def run
        fail 'Not implemented.'
    end

end

end
end
end
end
end
