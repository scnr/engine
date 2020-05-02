=begin
    Copyright 2020 Alex Douckas <alexdouckas@gmail.com>, Tasos Laskos <tasos.laskos@gmail.com>

    This file is part of the SCNR::Engine project and is subject to
    redistribution and commercial restrictions. Please see the SCNR::Engine
    web site for more information on licensing and terms of use.
=end

require_relative 'signature_common'

module SCNR::Engine::Support

# Represents a signature, used to maintain a lightweight representation of a
# {String} and refine it using similar {String}s to remove noise.
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
class SignatureRuby
    include SignatureCommon

    CACHE.merge!( tokens: Cache::LeastRecentlyPushed.new( size: 100 ) )

    attr_reader :tokens

    # @note The string will be tokenized based on whitespace.
    #
    # @param    [String, Signature]    data
    #   Seed data to use to initialize the signature.
    # @param    [Hash]    options
    # @option   options :threshold  [Float]
    #   Sets the maximum allowed {#differences} when performing
    #   {#similar? similarity} comparisons.
    def initialize( data, options = {} )
        @tokens  = tokenize( data )
        @options = options

        if @options[:threshold] && !@options[:threshold].is_a?( Numeric )
            fail ArgumentError, 'Option :threshold must be a number.'
        end
    end

    def clear
        @hash_cache = nil
        @tokens.clear
        self
    end

    def size
        @tokens.size
    end

    # @note The string will be tokenized based on whitespace.
    #
    # @param    [String, Signature]    data
    #   Data to use to refine the signature.
    #
    # @return   [Signature]
    #   `self`
    def refine!( data )
        @hash_cache = nil
        @tokens &= tokenize( data )
        self
    end

    def <<( data )
        @hash_cache = nil
        @tokens.merge tokenize( data )
        self
    end

    # @note The string will be tokenized based on whitespace.
    #
    # @param    [String, Signature]    data
    #   Data to use to refine the signature.
    #
    # @return   [Signature]
    #   New, refined signature.
    def refine( data )
        dup.refine!( data )
    end

    # @param    [Signature] other
    #
    # @return   [Float]
    #   Ratio of difference between signatures.
    def differences( other )
        return 1 if other.nil?
        return 0 if self == other

        ((tokens - other.tokens) | (other.tokens - tokens)).size /
            Float((other.tokens | tokens).size)
    end

    # @param    [Signature] other
    # @param    [Integer] threshold
    #   Threshold of {#differences differences}.
    #
    # @return   [Bool]
    def similar?( other, threshold = @options[:threshold] )
        fail 'No threshold given.' if !threshold
        self == other || differences( other ) <= threshold
    end

    def empty?
        @tokens.empty?
    end

    # @return [Signature]
    #   Copy of `self`.
    def dup
        self.class.new( '' ).tap { |s| s.copy( @hash_cache, tokens, @options ) }
    end

    def hash
        @hash_cache ||= tokens.hash
    end

    # @param [Signature]    other
    def ==( other )
        hash == other.hash
    end

    protected

    def copy( hash, tokens, options )
        @hash_cache = hash
        @tokens     = tokens.dup
        @options    = options.dup
    end

    private

    # @param    [Signature, String] data
    #
    # @return [Array<String,Integer>]
    #   Words as tokens.
    def tokenize( data )
        return data.tokens if data.is_a? self.class

        (CACHE[:tokens][data] ||= compress( data.split( /\W/ ) )).dup
    end

    # Compresses the tokens by only storing unique #hash values.
    # Seems kinda silly but this can actually save us GB of RAM when comparing
    # large signatures, not to mention CPU cycles.
    def compress( tokens )
        s = Set.new
        tokens.each do |token|
            # Left-over non-word characters will be on their own, this is a
            # low-overhead way to dispose of them.
            next if token.empty?

            s << token.hash
        end
        s
    end

end
end
