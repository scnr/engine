=begin
    Copyright 2020-2022 Tasos Laskos <tasos.laskos@gmail.com>

    This file is part of the SCNR::Engine project and is subject to
    redistribution and commercial restrictions. Please see the SCNR::Engine
    web site for more information on licensing and terms of use.
=end

module SCNR::Engine
class State

# @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
class Options

    def statistics
        {
            url:     SCNR::Engine::Options.url,
            checks:  SCNR::Engine::Options.checks,
            plugins: SCNR::Engine::Options.plugins.keys
        }
    end

    def dump( directory )
        FileUtils.mkdir_p( directory )
        SCNR::Engine::Options.save( "#{directory}/options" )
    end

    def self.load( directory )
        SCNR::Engine::Options.load( "#{directory}/options" )
        new
    end

    def clear
    end

end

end
end
