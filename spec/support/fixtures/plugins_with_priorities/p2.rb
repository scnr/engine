=begin
    Copyright 2024 Ecsypno Single Member P.C.

    This file is part of the SCNR::Engine project and is subject to
    redistribution and commercial restrictions. Please see the SCNR::Engine
    web site for more information on licensing and terms of use.
=end

class SCNR::Engine::Plugins::P2 < SCNR::Engine::Plugin::Base
    def self.info
        {
            name:     'P2',
            author:   'Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>',
            priority: 2
        }
    end
end
