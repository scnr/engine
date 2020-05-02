=begin
    Copyright 2020 Alex Douckas <alexdouckas@gmail.com>, Tasos Laskos <tasos.laskos@gmail.com>

    This file is part of the SCNR::Engine project and is subject to
    redistribution and commercial restrictions. Please see the SCNR::Engine
    web site for more information on licensing and terms of use.
=end

module SCNR::Engine
class Data

# Data for {SCNR::Engine::Session}.
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
class Session

    # @return   [Hash]
    attr_reader :configuration

    def initialize
        @configuration = {}
    end

    def statistics
        {}
    end

    def dump( directory )
        FileUtils.mkdir_p( directory )

        IO.binwrite( "#{directory}/configuration", Marshal.dump( @configuration ) )
    end

    def self.load( directory )
        session = new
        session.configuration.merge! Marshal.load( IO.binread( "#{directory}/configuration" ) )
        session
    end

    def clear
        @configuration.clear
    end

end

end
end

