=begin
    Copyright 2020 Alex Douckas <alexdouckas@gmail.com>, Tasos Laskos <tasos.laskos@gmail.com>

    This file is part of the SCNR::Engine project and is subject to
    redistribution and commercial restrictions. Please see the SCNR::Engine
    web site for more information on licensing and terms of use.
=end

require_relative 'signature_common'

module SCNR::Engine::Support

# Defined in Rust extension, we add some type conversion overrides here
# because some things are easier to do in Ruby than Rust.
class SignatureExt
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
        data.is_a?( SignatureExt ) ? data : self.class.for( data )
    end

end
end
