=begin
    Copyright 2020 Alex Douckas <alexdouckas@gmail.com>, Tasos Laskos <tasos.laskos@gmail.com> 

    This file is part of the SCNR::Engine project and is subject to
    redistribution and commercial restrictions. Please see the SCNR::Engine
    web site for more information on licensing and terms of use.
=end

module SCNR::Engine::Element
class Cookie
module Capabilities

# Extends {Engine::Element::Capabilities::Mutable} with {Cookie}-specific
# functionality.
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
module Mutable
    include SCNR::Engine::Element::Capabilities::Mutable

    # Overrides {Engine::Element::Capabilities::Mutable#each_mutation} to handle cookie-specific
    # limitations and the {Engine::OptionGroups::Audit#cookies_extensively} option.
    #
    # @param (see SCNR::Engine::Element::Capabilities::Mutable#each_mutation)
    # @return (see SCNR::Engine::Element::Capabilities::Mutable#each_mutation)
    # @yield (see SCNR::Engine::Element::Capabilities::Mutable#each_mutation)
    # @yieldparam (see SCNR::Engine::Element::Capabilities::Mutable#each_mutation)
    #
    # @see Engine::Element::Capabilities::Mutable#each_mutation
    def each_mutation( payload, options = {}, &block )
        options              = prepare_mutation_options( options )
        parameter_names      = options.delete( :parameter_names )
        with_extra_parameter = options.delete( :with_extra_parameter )
        extensively          = options[:extensively]
        extensively          = SCNR::Engine::Options.audit.cookies_extensively? if extensively.nil?

        super( payload, options ) do |element|
            yield element

            next if !extensively
            element.each_extensive_mutation( element, &block )
        end

        if with_extra_parameter
            if valid_input_name?( EXTRA_NAME )
                each_formatted_payload( payload, options[:format] ) do |format, formatted_payload|

                    element                     = self.dup
                    element.affected_input_name = EXTRA_NAME
                    element.inputs              = { EXTRA_NAME => formatted_payload }
                    element.format              = format
                    yield element if block_given?
                end
            else
                print_debug_level_2 'Extra name not supported as input name by' <<
                                        " #{audit_id}: #{payload.inspect}"
            end
        end

        if parameter_names
            if valid_input_name_data?( payload )
                element                     = self.dup
                element.affected_input_name = FUZZ_NAME
                element.inputs              = { payload => FUZZ_NAME_VALUE }
                element.seed                = payload
                yield element if block_given?
            else
                print_debug_level_2 'Payload not supported as input name by' <<
                                        " #{audit_id}: #{payload.inspect}"
            end
        end

        nil
    end

    def each_extensive_mutation( mutation )
        return if orphan?

        (auditor.page.links | auditor.page.forms).each do |e|
            next if e.inputs.empty?

            c = e.dup
            c.affected_input_name = "Mutation for the '#{name}' cookie"
            c.auditor = auditor
            c.audit_options[:submit] ||= {}
            c.audit_options[:submit][:cookies] = mutation.inputs.dup

            SCNR::Engine::Options.input.fill( c )

            yield c
        end
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
