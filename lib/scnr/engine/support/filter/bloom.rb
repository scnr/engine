=begin
    Copyright 2020-2022 Tasos Laskos <tasos.laskos@gmail.com>

    This file is part of the SCNR::Engine project and is subject to
    redistribution and commercial restrictions. Please see the SCNR::Engine
    web site for more information on licensing and terms of use.
=end

require 'bloomfilter-rb'

module SCNR::Engine
module Support::Filter


# Filter based on a Set.
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
class Bloom < Base

    class Collection
        attr_reader :filter

        def initialize( options = {} )
            @filter = BloomFilter::Native.new( options )
            @entry_count = 0
        end

        def <<( entry )
            @filter.insert entry
        ensure
            @entry_count += 1
        end

        def include?( entry )
            @filter.include? entry
        end

        def size
            @entry_count
        end

        def empty?
            size == 0
        end

        def any?
            !empty?
        end

        def clear
            @filter.clear
        ensure
            @entry_count = 0
        end

        def merge( other )
            @filter.merge! other.filter
            @filter
        end
    end

    # @param    (see Base#initialize)
    def initialize(*)
        super

        @collection = Collection.new( size: @options[:size] )
    end

end

end
end
