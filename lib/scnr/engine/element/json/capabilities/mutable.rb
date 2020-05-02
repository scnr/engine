=begin
    Copyright 2020 Tasos Laskos <tasos.laskos@gmail.com>

    This file is part of the SCNR::Engine project and is subject to
    redistribution and commercial restrictions. Please see the SCNR::Engine
    web site for more information on licensing and terms of use.
=end

module SCNR::Engine::Element
class JSON
module Capabilities

# Extends {Engine::Element::Capabilities::Mutable} with {JSON}-specific
# functionality.
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
module Mutable
    include SCNR::Engine::Element::Capabilities::Mutable

    # Overrides {Engine::Element::Capabilities::Mutable#affected_input_name=}
    # to allow for non-string data of variable depth.
    #
    # @param    [Array<String>, String]    name
    #   Sets the name of the fuzzed input.
    #
    #   If the `name` is an `Array`, it will be treated as a path to the location
    #   of the input.
    #
    # @see  Engine::Element::Capabilities::Mutable#affected_input_name=
    def affected_input_name=( name )
        if name.is_a?( Array ) && name.size == 1
            name = name.first
        end

        @affected_input_name = name
    end

    # @note (see SCNR::Engine::Element::Capabilities::Mutable#each_mutation)
    #
    # Overrides {Engine::Element::Capabilities::Mutable#each_mutation} to allow
    # for auditing of non-string data of variable depth.
    #
    # @param    (see SCNR::Engine::Element::Capabilities::Mutable#each_mutation)
    # @yield    (see SCNR::Engine::Element::Capabilities::Mutable#each_mutation)
    #
    # @see  Engine::Element::Capabilities::Mutable#each_mutation
    def each_mutation( payload, options = {}, &block )
        return if self.inputs.empty?

        if !valid_input_data?( payload )
            print_debug_level_2 "Payload not supported by #{self}: #{payload.inspect}"
            return
        end

        print_debug_trainer( options )
        print_debug_formatting( options )

        options   = prepare_mutation_options( options )
        generated = SCNR::Engine::Support::LookUp::Hash.new

        if options[:parameter_values]
            options[:format].each do |format|
                traverse_inputs do |path, value|
                    next if immutable_input?( path )

                    create_and_yield_if_unique( generated, {}, payload, path,
                                                format_str( payload, format, value.to_s ), format, &block
                    )
                end
            end
        end

        if options[:with_extra_parameter]
            if valid_input_name?( EXTRA_NAME )
                each_formatted_payload( payload, options[:format] ) do |format, formatted_payload|
                    elem                     = self.dup
                    elem.affected_input_name = EXTRA_NAME
                    elem.inputs              =
                        elem.inputs.merge( EXTRA_NAME => formatted_payload )
                    elem.seed                = payload
                    elem.format              = format

                    yield_if_unique( elem, generated, &block )
                end
            else
                print_debug_level_2 'Extra name not supported as input name by' <<
                                        " #{audit_id}: #{payload.inspect}"
            end
        end

        if options[:parameter_names]
            if valid_input_name_data?( payload )
                elem                     = self.dup
                elem.affected_input_name = FUZZ_NAME
                elem.inputs              = elem.inputs.merge( payload => FUZZ_NAME_VALUE )
                elem.seed                = payload

                yield_if_unique( elem, generated, &block )
            else
                print_debug_level_2 'Payload not supported as input name by' <<
                                        " #{audit_id}: #{payload.inspect}"
            end
        end

        nil
    end

    private

    def prepare_mutation_options( options )
        options = super( options )
        options.delete( :with_raw_payloads )
        options
    end

    def immutable_input?( path )
        [path].flatten.each do |name|
            return true if immutables.include?( name )
        end
        false
    end

end

end
end
end
