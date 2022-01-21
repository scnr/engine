=begin
    Copyright 2020-2022 Tasos Laskos <tasos.laskos@gmail.com>

    This file is part of the SCNR::Engine project and is subject to
    redistribution and commercial restrictions. Please see the SCNR::Engine
    web site for more information on licensing and terms of use.
=end

# @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
class SCNR::Engine::Checks::NoSqlInjection < SCNR::Engine::Check::Base

    # Payloads that will hopefully cause the webapp to output  error messages
    # if included as part of a query.
    PAYLOADS = { mongodb: '\';.")' }

    def self.error_signatures
        return @error_signatures if @error_signatures

        @error_signatures = {}
        Dir[File.dirname( __FILE__ ) + '/no_sql_injection/substrings/*'].each do |file|
            @error_signatures[File.basename( file ).to_sym] =
                IO.read( file ).split( "\n" )
        end

        @error_signatures
    end

    def self.options
        @options ||= {
            format:     [Format::APPEND],
            signatures: error_signatures
        }
    end

    def run
        audit PAYLOADS, self.class.options
    end

    def self.info
        {
            name:        'NoSQL Injection',
            description: %q{
NoSQL injection check, uses known DB errors to identify vulnerabilities.
},
            elements:    ELEMENTS_WITH_INPUTS,
            sink:        {
                areas: [:active],
                seed:  PAYLOADS.values.join
            },
            cost:        calculate_signature_analysis_cost( PAYLOADS.values.flatten.size, options ),
            author:      'Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>',
            version:     '0.1.3',
            platforms:   PAYLOADS.keys,

            issue:       {
                name:            %q{NoSQL Injection},
                description:     %q{
A NoSQL injection occurs when a value originating from the client's request is
used within a NoSQL call without prior sanitisation.

This can allow cyber-criminals to execute arbitrary NoSQL code and thus steal data,
or use the additional functionality of the database server to take control of
further server components.

Engine discovered that the affected page and parameter are vulnerable. This
injection was detected as Engine was able to discover known error messages within
the server's response.
},
                tags:            %w(nosql injection regexp database error),
                references:  {
                    'OWASP' => 'https://www.owasp.org/index.php/Testing_for_NoSQL_injection'
                },
                cwe:             89,
                severity:        Severity::HIGH,
                remedy_guidance: %q{
The most effective remediation against NoSQL injection attacks is to ensure that
NoSQL API calls are not constructed via string concatenation that includes
unsanitized data.

Sanitization is best achieved using existing escaping libraries.
}
            }
        }
    end

end
