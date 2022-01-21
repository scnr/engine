=begin
    Copyright 2020-2022 Tasos Laskos <tasos.laskos@gmail.com>

    This file is part of the SCNR::Engine project and is subject to
    redistribution and commercial restrictions. Please see the SCNR::Engine
    web site for more information on licensing and terms of use.
=end

class SCNR::Engine::Reporters::WithOutfile < SCNR::Engine::Reporter::Base
    def run
    end

    def self.info
        super.merge( options: [ SCNR::Engine::Reporter::Options.outfile('.stuff') ] )
    end
end
