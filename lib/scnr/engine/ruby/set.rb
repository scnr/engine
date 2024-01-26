=begin
    Copyright 2024 Ecsypno Single Member P.C.

    This file is part of the SCNR::Engine project and is subject to
    redistribution and commercial restrictions. Please see the SCNR::Engine
    web site for more information on licensing and terms of use.
=end

require 'set'

class Set

    def shift
        return if @hash.empty?

        key = @hash.first.first
        @hash.delete key
        key
    end

end
