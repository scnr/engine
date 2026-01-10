=begin
    Copyright 2024 Ecsypno Single Member P.C.

    This file is part of the SCNR::Engine project and is subject to
    redistribution and commercial restrictions. Please see the SCNR::Engine
    web site for more information on licensing and terms of use.
=end

require_relative 'signature_common'

module SCNR::Engine
module Support

# Instance methods module that will be extended onto Rust::Support::Signature instances.
# 
# Due to Magnus typed_data limitations with Ruby subclassing, we use a module extension
# pattern instead of traditional inheritance. This module provides the Ruby wrapper
# methods that handle String-to-Signature coercion for the Rust extension methods.
module SignatureExtInstanceMethods
    def refine!( data )
        refine_bang_ext normalize( data )
    end

    def refine( data )
        # Create a new signature by duping and refining
        result = dup
        SignatureExt.extend_with_methods(result, signature_ext_class)
        result.refine! data
        result
    end
    
    # Override dup to ensure extended methods are preserved
    def dup
        # Call the Rust dup method to copy the data
        rust_copy = super
        # Extend the copy with our methods
        SignatureExt.extend_with_methods(rust_copy, signature_ext_class)
        rust_copy
    end
    
    def differences( other )
        differences_ext normalize( other )
    end
    
    def similar?( other, threshold )
        is_similar_ext normalize( other ), threshold
    end
    
    def ==( other )
        return false unless other.is_a?( Rust::Support::Signature )
        is_equal_ext other
    end

    def <<( data )
        super data.delete( "\0" )
    end

    private

    def signature_ext_class
        @signature_ext_class || SignatureExt
    end

    def normalize( data )
        data.is_a?( Rust::Support::Signature ) ? data : signature_ext_class.for( data )
    end
end

# Ruby wrapper for Rust::Support::Signature that adds type conversion and coercion.
#
# @note Due to Magnus typed_data limitations, instances created by {.new} are technically
#   {SCNR::Engine::Rust::Support::Signature} objects extended with {SignatureExtInstanceMethods}.
#   This is necessary because Magnus doesn't support proper Ruby subclassing of typed data.
#   The practical effect is that all public methods work as expected, but `instance.class`
#   will return `SCNR::Engine::Rust::Support::Signature` instead of `SignatureExt`.
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
class SignatureExt < Rust::Support::Signature
    include SignatureCommon

    # Extends a Signature instance with SignatureExtInstanceMethods
    #
    # @param [Rust::Support::Signature] instance
    #   The instance to extend
    # @param [Class] klass
    #   The SignatureExt class to associate with the instance
    #
    # @return [void]
    # @api private
    def self.extend_with_methods(instance, klass = self)
        instance.extend(SignatureExtInstanceMethods)
        instance.instance_variable_set(:@signature_ext_class, klass)
    end

    # Creates a new Signature instance with String coercion support.
    #
    # @param [String] string
    #   The string to create a signature from. Null bytes will be removed.
    #
    # @return [Rust::Support::Signature]
    #   An instance extended with {SignatureExtInstanceMethods} that provides
    #   String coercion for refinement methods.
    #
    # @note The returned instance is technically a {Rust::Support::Signature},
    #   not a {SignatureExt}, due to Magnus typed_data constraints.
    def self.new( string )
        # Create a Rust Signature - this will be a Rust::Support::Signature instance
        instance = Rust::Support::Signature.new(string.delete("\0"))
        
        # Extend it with SignatureExt's instance methods
        extend_with_methods(instance, self)
        
        instance
    end

end
end
end
