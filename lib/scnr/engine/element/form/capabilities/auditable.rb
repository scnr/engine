=begin
    Copyright 2020-2022 Tasos Laskos <tasos.laskos@gmail.com>

    This file is part of the SCNR::Engine project and is subject to
    redistribution and commercial restrictions. Please see the SCNR::Engine
    web site for more information on licensing and terms of use.
=end

module SCNR::Engine::Element
class Form
module Capabilities

# Extends {Engine::Element::Capabilities::Auditable} with {Form}-specific
# functionality.
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
module Auditable
    include SCNR::Engine::Element::Capabilities::Auditable

    def audit_status_message
        override = nil
        if mutation_with_original_values?
            override = 'original'
        elsif mutation_with_sample_values?
            override = 'sample'
        end

        if override
            "Submitting form with #{override} values for #{inputs.keys.join(', ')}" <<
                " at '#{@action}'."
        else
            super
        end
    end

    # @param   (see SCNR::Engine::Element::Capabilities::Auditable#audit_id)
    # @return  (see SCNR::Engine::Element::Capabilities::Auditable#audit_id)
    def audit_id( payload = nil )
        force_train? ? id : super( payload )
    end

end
end
end
end
