=begin
    Copyright 2020 Tasos Laskos <tasos.laskos@gmail.com> 

    This file is part of the SCNR::Engine project and is subject to
    redistribution and commercial restrictions. Please see the SCNR::Engine
    web site for more information on licensing and terms of use.
=end

# Floating point option.
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
class SCNR::Engine::Component::Options::Float < SCNR::Engine::Component::Options::Base

    def normalize
        Float( effective_value ) rescue nil
    end

    def valid?
        super && normalize
    end

    def type
        :float
    end

end
