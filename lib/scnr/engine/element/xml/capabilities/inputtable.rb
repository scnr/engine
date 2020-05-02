=begin
    Copyright 2020 Tasos Laskos <tasos.laskos@gmail.com>

    This file is part of the SCNR::Engine project and is subject to
    redistribution and commercial restrictions. Please see the SCNR::Engine
    web site for more information on licensing and terms of use.
=end

module SCNR::Engine::Element
class XML
module Capabilities

# Extends {Engine::Element::Capabilities::Inputtable} with {XML}-specific
# functionality.
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
module Inputtable
    include SCNR::Engine::Element::Capabilities::Inputtable

    INVALID_INPUT_DATA = [ "\0" ]

    def valid_input_data?( data )
        !INVALID_INPUT_DATA.find { |c| data.include? c }
    end

    # @param    [String]    name
    #   Input name.
    #
    # @return   [Bool]
    #   `true` if the `name` is a valid CSS path for the XML
    #   {Element::Capabilities::WithSource#source}, `false` otherwise.
    def valid_input_name?( name )
        @inputs.include? name
    end

end

end
end
end
