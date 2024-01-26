=begin
    Copyright 2024 Ecsypno Single Member P.C.

    This file is part of the SCNR::Engine project and is subject to
    redistribution and commercial restrictions. Please see the SCNR::Engine
    web site for more information on licensing and terms of use.
=end

# @author  Tasos Laskos <tasos.laskos@gmail.com>
class SCNR::Engine::Checks::ServerHeader < SCNR::Engine::Check::Base

    def run
        return if audited?( page.response.headers['Server'] ) ||
          page.response.headers.empty? ||
          !page.response.headers['Server'] || page.code != 200

        audited( page.response.headers['Server'] )

        log(
          vector: Element::Server.new( page.url ),
          proof:  page.response.headers['Server']
        )
    end

    def self.info
        {
          name:        'Server header',
          description: %q{Checks the existence of a `Server` header.},
          author:      'Tasos Laskos <tasos.laskos@gmail.com>',
          version:     '0.1',
          elements:    [ Element::Server ],

          issue:       {
            name:        %q{'Server' header},
            description: %q{
The `Server` header describes the software used by the origin server that handled
the request — that is, the server that generated the response.

Avoid overly-detailed `Server` values, as they can reveal information that may make
it (slightly) easier for attackers to exploit known security holes.
},
            references:  {
              'MDN'   => 'https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Server'
            },
            cwe:         200,
            severity:    Severity::LOW,
            remedy_guidance: %q{
Configure your web server to not send a `Server` header.
}
          }
        }
    end

end
