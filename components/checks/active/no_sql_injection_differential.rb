=begin
    Copyright 2020 Alex Douckas <alexdouckas@gmail.com>, Tasos Laskos <tasos.laskos@gmail.com>

    This file is part of the SCNR::Engine project and is subject to
    redistribution and commercial restrictions. Please see the SCNR::Engine
    web site for more information on licensing and terms of use.
=end

# @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
class SCNR::Engine::Checks::NoSqlInjectionDifferential < SCNR::Engine::Check::Base

    def self.options
        return @options if @options

        pairs  = []
        [ '\'', '"', '' ].each do |q|
            {
                '%q;return true;var foo=%q' => '%q;return false;var foo=%q',
                '1%q||this%q'               => '1%q||!this%q'
            }.each do |s_true, s_false|
                pairs << { s_true.gsub( '%q', q ) => s_false.gsub( '%q', q ) }
            end
        end

        @options = { false: '-1839', pairs: pairs }
    end

    def run
        audit_differential self.class.options
    end

    def self.info
        {
            name:        'Blind NoSQL Injection (differential analysis)',
            description: %q{
It uses differential analysis to determine how different inputs affect the behavior
of the web application and checks if the displayed behavior is consistent with
that of a vulnerable application.
},
            elements:    [ Element::Link, Element::Form, Element::Cookie, Element::NestedCookie ],
            sink:        {
                areas: [:active]
            },
            cost:        calculate_differential_analysis_cost( options ),
            author:      'Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>',
            version:     '0.1.3',
            platforms:   [ :nosql ],

            issue:       {
                name:            %q{Blind NoSQL Injection (differential analysis)},
                description:     %q{
A NoSQL injection occurs when a value originating from the client's request is
used within a NoSQL call without prior sanitisation.

This can allow cyber-criminals to execute arbitrary NoSQL code and thus steal data,
or use the additional functionality of the database server to take control of
further server components.

Engine discovered that the affected page and parameter are vulnerable. This
injection was detected as Engine was able to inject specific NoSQL queries that
if vulnerable result in the responses for each injection being different. This is
known as a blind NoSQL injection vulnerability.
},
                tags:            %w(nosql blind differential injection database),
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
