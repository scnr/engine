=begin
    Copyright 2020-2022 Tasos Laskos <tasos.laskos@gmail.com>

    This file is part of the SCNR::Engine Framework project and is subject to
    redistribution and commercial restrictions. Please see the SCNR::Engine Framework
    web site for more information on licensing and terms of use.
=end

# Used to enable a sink-trace training session when no other checks are loaded.
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
class SCNR::Engine::Checks::Trainer < SCNR::Engine::Check::Base

    def self.info
        {
            name:        'Trainer',
            description: %q{
Forces the system learn from the responses of element submission with default
and benign sample values.
},
            author:      'Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>',
            elements:    [ Element::Form, Element::Link, Element::Cookie, Element::Header ],
            sink:        {
                # Triggers the least expensive type of sink trace.
                areas: [:body],
            },

            # Don't let the sink-tracer think we're better off without it.
            cost:        999999,
            version:     '0.2'
        }
    end

end
