=begin
    Copyright 2020-2022 Tasos Laskos <tasos.laskos@gmail.com>

    This file is part of the SCNR::Engine project and is subject to
    redistribution and commercial restrictions. Please see the SCNR::Engine
    web site for more information on licensing and terms of use.
=end

module SCNR::Engine::Element
class DOM
module Capabilities

# @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
module Inputtable
    include SCNR::Engine::Element::Capabilities::Inputtable

    INVALID_INPUT_DATA = [ "\0" ]

    def valid_input_data?( data )
        !INVALID_INPUT_DATA.find { |c| data.include? c }
    end

end

end
end
end
