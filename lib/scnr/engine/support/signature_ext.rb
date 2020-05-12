=begin
    Copyright 2020 Tasos Laskos <tasos.laskos@gmail.com>

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

    alias :old_refine! :refine!
    def refine!( data )
        old_refine! normalize( data )
    end

    alias :old_refine :refine
    def refine( data )
        old_refine normalize( data )
    end

    private

    def normalize( data )
        data.is_a?( Rust::Support::Signature ) ? data : self.class.for( data )
    end

end
end
end
