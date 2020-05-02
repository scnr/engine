=begin
    Copyright 2020 Tasos Laskos <tasos.laskos@gmail.com>

    This file is part of the SCNR::Engine project and is subject to
    redistribution and commercial restrictions. Please see the SCNR::Engine
    web site for more information on licensing and terms of use.
=end

# Logs all non 200 (OK) and non 404 server responses.
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
class SCNR::Engine::Checks::InterestingResponses < SCNR::Engine::Check::Base

    IGNORE_CODES = [ 200, 404 ].to_set

    def self.ran?
        @ran ||= false
    end

    def self.ran
        @ran = true
    end

    def run
        return if self.class.ran?

        # tell the HTTP interface to call this block every-time a request completes
        http.on_complete { |response| check_and_log( response ) }
    end

    def clean_up
        self.class.ran
    end

    def check_and_log( response )
        return if IGNORE_CODES.include?( response.code ) ||
            response.body.to_s.empty? || issue_limit_reached? ||
            response.scope.out?

        path = uri_parse( response.url ).path

        return if audited?( path ) || audited?( response.body )

        audited( path )
        audited( response.body )

        log(
             proof:    response.status_line,
             vector:   Element::Server.new( response.url ),
             response: response
        )
        print_ok "Found an interesting response -- Code: #{response.code}."
    end

    def self.info
        {
            name:        'Interesting responses',
            description: %q{Logs all non 200 (OK) server responses.},
            elements:    [ Element::Server ],
            author:      'Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>',
            version:     '0.2.1',

            issue:       {
                name:        %q{Interesting response},
                description: %q{
The server responded with a non 200 (OK) nor 404 (Not Found) status code.
This is a non-issue, however exotic HTTP response status codes can provide useful
insights into the behavior of the web application and assist with the penetration test.
},
                references:  {
                    'w3.org' => 'http://www.w3.org/Protocols/rfc2616/rfc2616-sec10.html'
                },
                tags:        %w(interesting response server),
                severity:    Severity::INFORMATIONAL
            },
            max_issues: 25
        }
    end

end
