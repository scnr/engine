=begin
    Copyright 2020-2022 Tasos Laskos <tasos.laskos@gmail.com>

    This file is part of the SCNR::Engine project and is subject to
    redistribution and commercial restrictions. Please see the SCNR::Engine
    web site for more information on licensing and terms of use.
=end

module SCNR::Engine::Element
class LinkTemplate
module Capabilities

# Extends {Engine::Element::Capabilities::Inputtable} with {LinkTemplate}-specific
# functionality.
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
module Inputtable
    include SCNR::Engine::Element::Capabilities::Inputtable

    INVALID_INPUT_DATA = [
        # Protocol URLs require a // which we can't preserve.
        '://'
    ]

    # @param    [String]    name
    #   Input name.
    #
    # @return   [Bool]
    #   `true` if the `name` can be found as a named capture in {LinkTemplate#template},
    #   `false` otherwise.
    def valid_input_name?( name )
        return if !@template
        @template.names.include? name
    end

    # @param    [String]    data
    #   Input data.
    #
    # @return   [Bool]
    #   `true` if the `data` don't contain strings specified in
    #   #{INVALID_INPUT_DATA}, `false` otherwise.
    #
    # @see INVALID_INPUT_DATA
    def valid_input_data?( data )
        !INVALID_INPUT_DATA.find { |c| data.include? c }
    end

end

end
end
end
