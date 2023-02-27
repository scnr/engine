=begin
    Copyright 2020-2022 Tasos Laskos <tasos.laskos@gmail.com>

    This file is part of the SCNR::Engine project and is subject to
    redistribution and commercial restrictions. Please see the SCNR::Engine
    web site for more information on licensing and terms of use.
=end

require 'set'

module SCNR::Engine
module Support::Filter

# Filter based on a Set.
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
class Set < Base

    # @param    (see Base#initialize)
    def initialize(*)
        super
        # @collection = Rust::Support::Filter::Set.new
        @collection = ::Set.new
    end

    def to_rpc_data
        [@options, @collection.to_a]
    end

    def self.from_rpc_data( data )
        options, items = data
        new( options ).merge items
    end

end

end
end
