=begin
    Copyright 2024 Ecsypno Single Member P.C.

    This file is part of the SCNR::Engine project and is subject to
    redistribution and commercial restrictions. Please see the SCNR::Engine
    web site for more information on licensing and terms of use.
=end

module SCNR::Engine::Element
class DOM
module Capabilities

# @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
module Mutable
    include SCNR::Engine::Element::Capabilities::Mutable

    private

    def prepare_mutation_options( options )
        options = super( options )
        # No sense in doing these for the DOM:
        #
        # Either payload will be raw in the first place or the browser will
        # override us.
        options.delete :with_raw_payloads

        # Browser handles the submission, there may not even be an HTTP request.
        options.delete :with_both_http_methods

        # DOM inputs are fixed.
        options.delete :parameter_names
        options.delete :with_extra_parameter

        options
    end

end

end
end
end
