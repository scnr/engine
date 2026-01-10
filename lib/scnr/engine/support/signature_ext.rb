=begin
    Copyright 2024 Ecsypno Single Member P.C.

    This file is part of the SCNR::Engine project and is subject to
    redistribution and commercial restrictions. Please see the SCNR::Engine
    web site for more information on licensing and terms of use.
=end

require_relative 'signature_common'

module SCNR::Engine
module Support

# Instance methods module that will be extended onto Rust::Support::Signature instances
module SignatureExtInstanceMethods
    def refine!( data )
        refine_bang_ext normalize( data )
    end

    def refine( data )
        # Create a new signature by duping and refining
        result = dup
        result.extend(SignatureExtInstanceMethods)
        result.instance_variable_set(:@signature_ext_class, signature_ext_class)
        result.refine! data
        result
    end
    
    # Override dup to ensure extended methods are preserved
    def dup
        # Call the Rust dup method to copy the data
        rust_copy = super
        # Extend the copy with our methods
        rust_copy.extend(SignatureExtInstanceMethods)
        rust_copy.instance_variable_set(:@signature_ext_class, signature_ext_class)
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

# Defined in Rust extension, we add some type conversion overrides here
# because some things are easier to do in Ruby than Rust.
class SignatureExt < Rust::Support::Signature
    include SignatureCommon

    def self.new( string )
        # Create a Rust Signature - this will be a Rust::Support::Signature instance
        instance = Rust::Support::Signature.new(string.delete("\0"))
        
        # Extend it with SignatureExt's instance methods
        instance.extend(SignatureExtInstanceMethods)
        instance.instance_variable_set(:@signature_ext_class, self)
        
        instance
    end
    
    # Include instance methods for when instances are created via other means
    include SignatureExtInstanceMethods

end
end
end
