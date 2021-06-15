=begin
    Copyright 2020 Tasos Laskos <tasos.laskos@gmail.com>

    This file is part of the SCNR::Engine project and is subject to
    redistribution and commercial restrictions. Please see the SCNR::Engine
    web site for more information on licensing and terms of use.
=end

module SCNR::Engine::Element
class Form
module Capabilities

# Extends {Engine::Element::Capabilities::Mutable} with {Form}-specific
# functionality.
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
module Mutable
    include SCNR::Engine::Element::Capabilities::Mutable

    # @return   [Bool]
    #   `true` if the element has not been mutated, `false` otherwise.
    def mutation_with_original_values?
        !!@mutation_with_original_values
    end

    def mutation_with_original_values
        @mutation_with_original_values = true
    end

    # @return   [Bool]
    #   `true` if the element has been populated with sample
    #   ({Engine::OptionGroups::Input#fill}) values, `false` otherwise.
    #
    # @see Engine::OptionGroups::Input
    def mutation_with_sample_values?
        !!@mutation_with_sample_values
    end

    def mutation_with_sample_values
        @mutation_with_sample_values = true
    end

    # Overrides {Engine::Element::Capabilities::Mutable#each_mutation} adding
    # support for mutations with:
    #
    # * Sample values (filled by {Engine::OptionGroups::Input#fill}).
    # * Original values.
    # * Password fields requiring identical values (in order to pass
    #   server-side validation)
    #
    # @param    [String]    payload
    #   Payload to inject.
    # @param    [Hash]      opts
    #   Mutation options.
    # @option   opts    [Bool]  :skip_original
    #   Whether or not to skip adding a mutation holding original values and
    #   sample values.
    #
    # @param (see SCNR::Engine::Element::Capabilities::Mutable#each_mutation)
    # @return (see SCNR::Engine::Element::Capabilities::Mutable#each_mutation)
    # @yield (see SCNR::Engine::Element::Capabilities::Mutable#each_mutation)
    # @yieldparam (see SCNR::Engine::Element::Capabilities::Mutable#each_mutation)
    #
    # @see Engine::Element::Capabilities::Mutable#each_mutation
    # @see Engine::OptionGroups::Input#fill
    def each_mutation( payload, opts = {} )
        opts = MUTATION_OPTIONS.merge( opts )

        generated = SCNR::Engine::Support::Filter::Set.new(hasher: :mutable_hash )

        # Completely remove fake inputs prior to mutation generation, they'll
        # be restored at the end of this method.
        pre_inputs = @inputs
        @inputs    = @inputs.reject{ |name, _| fake_field?( name ) }

        super( payload, opts ) do |elem|
            elem.mirror_password_fields
            yield elem if !generated.include?( elem )
            generated << elem
        end

        return if opts[:skip_original]

        elem = self.dup
        elem.mutation_with_original_values
        elem.affected_input_name = ORIGINAL_VALUES
        yield elem if !generated.include?( elem )
        generated << elem

        # Default select values, in case they reveal new resources.
        inputs.keys.each do |input|
            next if field_type_for( input ) != :select

            # We do the break inside the loop because #node is lazy parsed
            # and we don't want to parse it unless we have a select input.
            break if !node

            node.nodes_by_name( 'select' ) do |select_node|
                next if select_node['name'] != input

                select_node.nodes_by_name( 'option' ) do |child|
                    try_input do
                        elem = self.dup
                        elem.mutation_with_original_values
                        elem.affected_input_name  = input
                        elem.affected_input_value = child['value'] || child.text.strip
                        yield elem if !generated.include?( elem )
                        generated << elem
                    end
                end
            end
        end

        try_input do
            # Sample values, in case they reveal new resources.
            elem = self.dup

            SCNR::Engine::Options.input.fill( elem )

            elem.affected_input_name = SAMPLE_VALUES
            elem.mutation_with_sample_values
            yield elem if !generated.include?( elem )
            generated << elem
        end
    ensure
        @inputs = pre_inputs
    end

end
end
end
end
