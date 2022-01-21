=begin
    Copyright 2020-2022 Tasos Laskos <tasos.laskos@gmail.com>

    This file is part of the SCNR::Engine project and is subject to
    redistribution and commercial restrictions. Please see the SCNR::Engine
    web site for more information on licensing and terms of use.
=end

require_relative 'with_sinks/sinks'

module SCNR::Engine
module Element::DOM::Capabilities

# @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
module WithSinks
    include SCNR::Engine::Element::Capabilities::WithSinks

end

end
end
