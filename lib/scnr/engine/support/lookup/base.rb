=begin
    Copyright 2020 Alex Douckas <alexdouckas@gmail.com>, Tasos Laskos <tasos.laskos@gmail.com>

    This file is part of the SCNR::Engine project and is subject to
    redistribution and commercial restrictions. Please see the SCNR::Engine
    web site for more information on licensing and terms of use.
=end

module SCNR::Engine
module Support::LookUp

# @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
# @abstract
class Base

    attr_reader :collection

    DEFAULT_OPTIONS = {
        hasher: :hash
    }

    # @param    [Hash]  options
    # @option   options [Symbol]    (:hasher)
    #   Method to call on the item to obtain its hash.
    def initialize( options = {} )
        @options = DEFAULT_OPTIONS.merge( options )
        @hasher  = @options[:hasher].to_sym

        @mutex   = Mutex.new
    end

    # @param    [#persistent_hash] item
    #   Item to insert.
    #
    # @return   [Hash]
    #   `self`
    def <<( item )
        synchronize do
            @collection << calculate_hash( item )
            self
        end
    end
    alias :add :<<

    # @param    [#persistent_hash] item
    #   Item to delete.
    #
    # @return   [Hash]
    #   `self`
    def delete( item )
        synchronize do
            @collection.delete( calculate_hash( item ) )
        end
        self
    end

    # @param    [#persistent_hash] item
    #   Item to check.
    #
    # @return   [Bool]
    def include?( item )
        synchronize do
            @collection.include? calculate_hash( item )
        end
    end

    def empty?
        @collection.empty?
    end

    def any?
        !empty?
    end

    def size
        @collection.size
    end

    def clear
        synchronize do
            @collection.clear
        end
    end

    def ==( other )
        hash == other.hash
    end

    def hash
        @collection.hash
    end

    def dup
        self.class.new( @options.dup ).tap { |c| c.collection = @collection.dup }
    end

    def _dump( _ )
        Marshal.dump( [@options, @collection] )
    end

    def self._load( data )
        options, collection = Marshal.load( data )
        new( options ).tap { |n| n.collection = collection }
    end

    def collection=( c )
        @collection = c
    end

    private

    def calculate_hash( item )
        item.send @hasher
    end

    def synchronize( &block )
        @mutex.synchronize( &block )
    end

end

end
end
