=begin
    Copyright 2024 Ecsypno Single Member P.C.

    This file is part of the SCNR::Engine project and is subject to
    redistribution and commercial restrictions. Please see the SCNR::Engine
    web site for more information on licensing and terms of use.
=end

class SCNR::Engine::Reporters::Error < SCNR::Engine::Reporter::Base

    def run
        fail
    end

    def self.info
        super.merge( options: [ Options.outfile( 'foo' ) ] )
    end
end
