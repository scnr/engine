=begin
    Copyright 2020 Tasos Laskos <tasos.laskos@gmail.com>

    This file is part of the SCNR::Engine project and is subject to
    redistribution and commercial restrictions. Please see the SCNR::Engine
    web site for more information on licensing and terms of use.
=end

require 'google_hash'

module SCNR::Engine
module Support

# @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
class Hash
    include MonitorMixin
    include Enumerable

    attr_reader :type
    attr_reader :klass

    HASHES = {
        ruby: ::Hash
    }

    if SCNR::Engine.windows?
        HASHES.merge!(
            int_to_int:   HASHES[:ruby],
            int_to_long:  HASHES[:ruby],
            int_to_ruby:  HASHES[:ruby],
            long_to_int:  HASHES[:ruby],
            long_to_long: HASHES[:ruby],
            long_to_ruby: HASHES[:ruby],
            ruby_to_ruby: HASHES[:ruby]
        )
    else
        HASHES.merge!(
            int_to_int:   GoogleHashDenseIntToInt,
            int_to_long:  GoogleHashDenseIntToLong,
            int_to_ruby:  GoogleHashDenseIntToRuby,

            long_to_int:  GoogleHashDenseLongToInt,
            long_to_long: GoogleHashDenseLongToLong,
            long_to_ruby: GoogleHashDenseLongToRuby,

            # Takes up less space but is slower than :ruby.
            ruby_to_ruby: GoogleHashDenseRubyToRuby
        )
    end

    def initialize( type, data = {} )
        super()

        @type = type

        if !(@klass = HASHES[type])
            fail ArgumentError, "Unknown type: #{type}"
        end

        @collection = @klass.new

        merge! data
    end

    # Not guaranteed to be the first pushed depending on chosen type.
    def first
        synchronize do
            @collection.each { |k, v| return [k, v] }
        end
    end

    def []( k )
        synchronize do
            @collection[k]
        end
    end

    def []=( k, v )
        synchronize do
            @hash = nil
            @collection[k] = v
        end
    end

    def delete( item )
        synchronize do
            @hash = nil
            @collection.delete item
        end
    end

    def include?( item )
        synchronize do
            @collection.include? item
        end
    end

    def each( &block )
        synchronize do
            @collection.each( &block )
        end
    end

    def keys
        synchronize do
            @collection.keys
        end
    end

    def values
        synchronize do
            @collection.values
        end
    end

    def merge( other )
        synchronize do
            dup.merge! other
        end
    end

    def merge!( other )
        synchronize do
            @hash = nil

            case other
                when self.class, ::Hash
                    other.each do |k, v|
                        self[k] = v
                    end

                else
                    fail ArgumentError,
                         "Don't know how to merge with: #{other.class}"
            end
        end

        self
    end

    def hash
        synchronize do
            @hash ||= to_h.hash
        end
    end

    def ==( other )
        synchronize do
            hash == other.hash
        end
    end

    def size
        synchronize do
            @collection.size
        end
    end

    def empty?
        size == 0
    end

    def any?
        !empty?
    end

    def clear
        synchronize do
            @hash = nil
            @collection.clear
        end

        self
    end

    def to_h
        synchronize do
            h = {}
            @collection.each { |k, v| h[k] = v }
            h
        end
    end

    def dup
        synchronize do
            d = self.class.new( @type )
            each do |k, v|
                d[k] = v
            end
            d
        end
    end

    def _dump( _ )
        Marshal.dump( [@type, to_h] )
    end

    def self._load( data )
        type, data = Marshal.load( data )
        new( type.to_sym ).merge data
    end

end

end
end
