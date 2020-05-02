=begin
    Copyright 2020 Tasos Laskos <tasos.laskos@gmail.com>

    This file is part of the SCNR::Engine project and is subject to
    redistribution and commercial restrictions. Please see the SCNR::Engine
    web site for more information on licensing and terms of use.
=end

require 'google_hash'

module SCNR::Engine
module Support::LookUp
class Hash

# @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
class Collection

    def initialize
        if SCNR::Engine.windows?
            @collection = ::Hash.new
        else
            @collection = GoogleHashSparseLongToInt.new
        end
    end

    def <<( item )
        @collection[item] = 1
        self
    end

    def delete( item )
        @collection.delete item
    end

    def include?( item )
        @collection.include? item
    end

    def each( &block )
        @collection.each( &block )
    end

    def merge( other )
        case other
            when self.class
                other.collection.each do |k, _|
                    self << k
                end

            when Set, Array
                other.each do |k|
                    self << k
                end

            else
                fail ArgumentError,
                     "Don't know how to merge with: #{other.class}"
        end

        self
    end

    def hash
        to_a.sort.hash
    end

    def replace( other )
        @collection = other.collection
    end

    def size
        @collection.size
    end

    def empty?
        size == 0
    end

    def clear
        @collection.clear
    end

    def to_a
        a = []
        @collection.each { |item| a << item }
        a
    end

    def dup
        d = self.class.new
        d.merge( self )
        d
    end

    def _dump( _ )
        MessagePack.dump( to_a )
    end

    def self._load( data )
        new.merge MessagePack.load( data )
    end

    protected

    def collection
        @collection
    end

    def collection=( c )
        @collection = c
    end

end

end
end
end
