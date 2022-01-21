=begin
    Copyright 2020-2022 Tasos Laskos <tasos.laskos@gmail.com>

    This file is part of the SCNR::Engine project and is subject to
    redistribution and commercial restrictions. Please see the SCNR::Engine
    web site for more information on licensing and terms of use.
=end

require_relative 'with_sinks/sinks'

module SCNR::Engine
module Element::Capabilities

# @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
module WithSinks

    # @return   [Sinks]
    def sinks
        @sinks ||= self.class::Sinks.new( parent: self )
    end

    # @note Differences in input values will not be taken into consideration.
    #
    # @return  [String]
    #   String identifying self's coverage of the web application's input surface.
    def sink_id
        "#{action}:#{type}:#{default_inputs.keys.sort}"
    end

    # @return  [Integer]
    #   Digest of {Auditable#coverage_id}.
    def sink_hash
        sink_id.persistent_hash
    end

    def coverage_and_trace_id
        "#{self.coverage_id}:#{self.sinks.traced?}"
    end

    def coverage_and_trace_hash
        coverage_and_trace_id.persistent_hash
    end

    def to_rpc_data
        super.tap { |data| data.delete 'sinks' }
    end

end

end
end
