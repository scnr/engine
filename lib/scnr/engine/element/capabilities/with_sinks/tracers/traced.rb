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

class Traced < Base
    Sinks.register_tracer self, :traced
end

end
end
end
end
end
