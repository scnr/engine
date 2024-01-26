=begin
    Copyright 2024 Ecsypno Single Member P.C.

    This file is part of the SCNR::Engine project and is subject to
    redistribution and commercial restrictions. Please see the SCNR::Engine
    web site for more information on licensing and terms of use.
=end

module SCNR::Engine::OptionGroups

# @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
class Timeout < SCNR::Engine::OptionGroup

    # @return    [Integer]
    attr_accessor :duration

    # @return    [Bool]
    attr_accessor :suspend

    def suspend?
        !!suspend
    end

    def exceeded?( seconds )
        duration && seconds >= duration
    end

end
end
