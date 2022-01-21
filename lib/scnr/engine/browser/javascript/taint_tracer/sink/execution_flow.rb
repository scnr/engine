=begin
    Copyright 2020-2022 Tasos Laskos <tasos.laskos@gmail.com>

    This file is part of the SCNR::Engine project and is subject to
    redistribution and commercial restrictions. Please see the SCNR::Engine
    web site for more information on licensing and terms of use.
=end

module SCNR::Engine
class Browser
class Javascript
class TaintTracer
class Sink

# Represents an execution-flow trace.
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
class ExecutionFlow < Base

    # @return   [Array]
    #   Data passed to the `TaintTracer#log_execution_flow_sink` JS interface.
    attr_accessor :data

end

end
end
end
end
end
