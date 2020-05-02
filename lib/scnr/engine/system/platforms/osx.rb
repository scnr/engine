=begin
    Copyright 2020 Alex Douckas <alexdouckas@gmail.com>, Tasos Laskos <tasos.laskos@gmail.com>

    This file is part of the SCNR::Engine project and is subject to
    redistribution and commercial restrictions. Please see the SCNR::Engine
    web site for more information on licensing and terms of use.
=end

require_relative 'mixins/unix'

module SCNR::Engine

class System
module Platforms
class OSX < Base
    include Mixins::Unix

    # @return   [Integer]
    #   Amount of free RAM in bytes.
    def memory_free
        pagesize * memory.free
    end

    class <<self
        def current?
            SCNR::Engine.mac?
        end
    end

end
end
end
end
