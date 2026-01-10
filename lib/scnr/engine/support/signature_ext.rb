=begin
    Copyright 2024 Ecsypno Single Member P.C.

    This file is part of the SCNR::Engine project and is subject to
    redistribution and commercial restrictions. Please see the SCNR::Engine
    web site for more information on licensing and terms of use.
=end

require_relative 'signature_common'

module SCNR::Engine
module Support

# Defined in Rust extension, we add some type conversion overrides here
# because some things are easier to do in Ruby than Rust.
class SignatureExt < Rust::Support::Signature
    include SignatureCommon

    def self.new( string )
        super string.delete( "\0" )
    end

    def refine!( data )
        refine_bang_ext normalize( data )
    end

    def refine( data )
        # Use dup which should preserve SignatureExt type in Ruby
        result = dup
        result.refine! data
        result
    end
    
    # Override dup to ensure SignatureExt type is preserved
    def dup
        # Call the Rust dup method to copy the data
        rust_copy = super
        # Wrap it in SignatureExt
        wrapped = self.class.allocate
        wrapped.send(:initialize_copy, rust_copy)
        wrapped
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

    def normalize( data )
        data.is_a?( Rust::Support::Signature ) ? data : self.class.for( data )
    end

end
end
end
