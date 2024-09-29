=begin
    Copyright 2024 Ecsypno Single Member P.C.

    This file is part of the SCNR::Engine project and is subject to
    redistribution and commercial restrictions. Please see the SCNR::Engine
    web site for more information on licensing and terms of use.
=end

module SCNR::Engine
module Support

# @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
class PersistentHash

    attr_reader :collection

    def initialize( initial_value = nil )
        @collection = Hash.new( initial_value )
    end

    def []=(k, v)
        @collection[hash_key( k )] = v
    end

    def []( k )
        @collection[hash_key( k )]
    end

    def merge!( other )
        @collection.merge! other.collection
    end
    
    def clear
        @collection.clear
    end

    def ==( other )
        self.hash == other.hash
    end

    def hash
        @collection.hash
    end

    private

    def hash_key( key )
        key.persistent_hash
    end

end

end
end
