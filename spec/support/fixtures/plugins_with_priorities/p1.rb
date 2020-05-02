=begin
    Copyright 2020 Alex Douckas <alexdouckas@gmail.com>, Tasos Laskos <tasos.laskos@gmail.com>

    This file is part of the SCNR::Engine project and is subject to
    redistribution and commercial restrictions. Please see the SCNR::Engine
    web site for more information on licensing and terms of use.
=end

class SCNR::Engine::Plugins::P1 < SCNR::Engine::Plugin::Base
    def self.info
        {
            name:     'P1',
            author:   'Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>',
            priority: 1
        }
    end
end
