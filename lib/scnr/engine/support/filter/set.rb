=begin
    Copyright 2020 Alex Douckas <alexdouckas@gmail.com>, Tasos Laskos <tasos.laskos@gmail.com>

    This file is part of the SCNR::Engine project and is subject to
    redistribution and commercial restrictions. Please see the SCNR::Engine
    web site for more information on licensing and terms of use.
=end

module SCNR::Engine
module Support::Filter

# Filter based on a Set.
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
class Set < Base

    # @param    (see Base#initialize)
    def initialize(*)
        super

        # if SCNR::Engine.has_extension?
        #     @collection = Rust::Support::Filter::Set.new
        # else
            require 'set'
            @collection = ::Set.new
        # end
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
