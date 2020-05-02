=begin
    Copyright 2020 Tasos Laskos <tasos.laskos@gmail.com>

    This file is part of the SCNR::Engine project and is subject to
    redistribution and commercial restrictions. Please see the SCNR::Engine
    web site for more information on licensing and terms of use.
=end

module SCNR::Engine::Element
class XML
module Capabilities

# Extends {Engine::Element::Capabilities::Mutable} with {XML}-specific
# functionality.
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
module Mutable
    include SCNR::Engine::Element::Capabilities::Mutable

    private

    def prepare_mutation_options( options )
        options = super( options )
        options.delete( :with_raw_payloads )
        options.delete( :parameter_names )
        options.delete( :with_extra_parameter )
        options
    end
end

end
end
end
