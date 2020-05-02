=begin
    Copyright 2020 Alex Douckas <alexdouckas@gmail.com>, Tasos Laskos <tasos.laskos@gmail.com> 

    This file is part of the SCNR::Engine project and is subject to
    redistribution and commercial restrictions. Please see the SCNR::Engine
    web site for more information on licensing and terms of use.
=end

module SCNR::Engine::Element
class Header
module Capabilities

# Extends {Engine::Element::Capabilities::Mutable} with {Header}-specific
# functionality.
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
module Mutable
    include SCNR::Engine::Element::Capabilities::Mutable

    # Overrides {Capabilities::Mutable#each_mutation} to handle header-specific
    # limitations.
    #
    # @param (see SCNR::Engine::Element::Capabilities::Mutable#each_mutation)
    # @return (see SCNR::Engine::Element::Capabilities::Mutable#each_mutation)
    # @yield (see SCNR::Engine::Element::Capabilities::Mutable#each_mutation)
    # @yieldparam (see SCNR::Engine::Element::Capabilities::Mutable#each_mutation)
    #
    # @see Capabilities::Mutable#each_mutation
    def each_mutation( payload, options = {}, &block )
        options = options.dup
        parameter_names = options.delete( :parameter_names )

        super( payload, options, &block )

        return if !parameter_names

        if !valid_input_name_data?( payload )
            print_debug_level_2 'Payload not supported as input name by' <<
                                    " #{audit_id}: #{payload.inspect}"
            return
        end

        elem = self.dup
        elem.affected_input_name = FUZZ_NAME
        elem.inputs = { payload => FUZZ_NAME_VALUE }
        yield elem
    end

    private

    def prepare_mutation_options( options )
        options = super( options )
        options.delete( :with_raw_payloads )
        options
    end

end

end
end
end
