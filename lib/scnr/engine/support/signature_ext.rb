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
        # Call the parent class method with normalized data
        # This ensures we get back a Signature that we can work with
        dup.refine! normalize( data )
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
