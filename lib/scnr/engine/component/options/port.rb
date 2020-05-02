=begin
    Copyright 2020 Alex Douckas <alexdouckas@gmail.com>, Tasos Laskos <tasos.laskos@gmail.com>

    This file is part of the SCNR::Engine project and is subject to
    redistribution and commercial restrictions. Please see the SCNR::Engine
    web site for more information on licensing and terms of use.
=end

# Network port option.
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
class SCNR::Engine::Component::Options::Port < SCNR::Engine::Component::Options::Base

    def normalize
        effective_value.to_i
    end

    def valid?
        return false if !super
        (1..65535).include?( normalize )
    end

    def type
        :port
    end

end
