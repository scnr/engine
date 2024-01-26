=begin
    Copyright 2024 Ecsypno Single Member P.C.

    This file is part of the SCNR::Engine project and is subject to
    redistribution and commercial restrictions. Please see the SCNR::Engine
    web site for more information on licensing and terms of use.
=end

# File inclusion check.
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
#
# @see http://cwe.mitre.org/data/definitions/98.html
# @see https://www.owasp.org/index.php/PHP_File_Inclusion
class SCNR::Engine::Checks::FileInclusion < SCNR::Engine::Check::Base

    def self.options
        @options ||= {
            format:     [Format::STRAIGHT],
            signatures: FILE_SIGNATURES_PER_PLATFORM.merge(
                # Generic PHP errors.
                php: [
                    'An error occurred in script',
                    'Failed opening required',
                    'failed to open stream:',
                    proc do |response|
                        next if !response.body.optimized_include?( "Failed opening '" )
                        /Failed opening '.*?' for inclusion/
                    end,
                    proc do |response|
                        next if !response.body.optimized_include?( '<b>Warning</b>:' )
                        /<b>Warning<\/b>:\s+(?:file|read_file|highlight_file|show_source)/
                    end
                ],
                perl: [
                    proc do |response|
                        next if !response.body.optimized_include?( ' line ' )
                        /in .* at .* line d+?\./
                    end
                ]
            ),
            each_mutation: proc do |mutation|
                next if !mutation.affected_input_value
                [ add_null( mutation ), add_file( mutation ) ]
            end
        }
    end

    # Generate one more mutation (on the fly) which will include the extension
    # of the original value (if that value was a filename) after a null byte.
    # If there was no extension it doesn't matter, we still need the appended null.
    def self.add_null( mutation )
        # Don't bother if the current element type can't carry nulls.
        return if !mutation.valid_input_value_data?( "\0" )

        m = mutation.dup

        # Figure out the extension of the default value, if it has one.
        ext = m.default_inputs[m.affected_input_name].to_s.split( '.' )
        ext = ext.size > 1 ? ext.last : nil

        # Null-terminate the injected value and append the ext.
        m.affected_input_value += "\0.#{ext}"

        # Pass our new element back to be audited.
        m
    end

    def self.add_file( mutation )
        original = mutation.default_inputs[mutation.affected_input_name].to_s.downcase
        return if !original.empty? && !original.start_with?( 'file:/' )

        m = mutation.dup
        m.affected_input_value = "file:/#{m.affected_input_value}"
        m
    end

    def self.payloads
        @payloads ||= {
            unix:    [
                '/proc/self/environ',
                '/etc/passwd'
            ],
            windows: [
                '/boot.ini',
                '/windows/win.ini',
                '/winnt/win.ini'
            ].map { |p| ["c:#{p}", "#{p}#{'.'* 700}", p.gsub( '/', '\\' ) ] }.flatten,
            java:    [ '/WEB-INF/web.xml', '\WEB-INF\web.xml' ]
        }
    end

    def run
        audit self.class.payloads, self.class.options
    end

    def self.info
        {
            name:        'File Inclusion',
            description: %q{
Injects paths of common files (like `/etc/passwd` and `boot.ini`) and evaluates
the existence of a file inclusion vulnerability based on the presence of relevant
content or errors in the HTTP response body.
},
            elements:    ELEMENTS_WITH_INPUTS,
            author:      'Tasos "Zapotek" Laskos <tasos.laskos@gmail.com> ',
            version:     '0.2.0',
            cost:        calculate_signature_analysis_cost( payloads.values.flatten.size, options ) * 2,
            sink:        {
              areas: [:active]
            },
            platforms:   options[:signatures].keys,

            issue:       {
                name:            %q{File Inclusion},
                description:     %q{
Web applications occasionally use parameter values to store the location of a file
which will later be required by the server.

An example of this is often seen in error pages, where the actual file path for
the error page is stored in a parameter value -- for example `example.com/error.php?page=404.php`.

A file inclusion occurs when the parameter value (ie. path to file) can be
substituted with the path of another resource on the same server, effectively
allowing the displaying of arbitrary, and possibly restricted/sensitive, files.

SCNR::Engine discovered that it was possible to substitute a parameter value with another
resource and have the server return the contents of the resource to the client within
the response.
},
                references:  {
                    'OWASP' => 'https://www.owasp.org/index.php/PHP_File_Inclusion'
                },
                tags:            %w(file inclusion error injection regexp),
                cwe:             98,
                severity:        Severity::HIGH,
                remedy_guidance: %q{
It is recommended that untrusted data is never used to form a file location to
be included.

To validate data, the application should ensure that the supplied value for a file
is permitted. This can be achieved by performing whitelisting on the parameter
value, by matching it against a list of permitted files. If the supplied value
does not match any value in the whitelist, then the server should redirect to a
standard error page.

In some scenarios, where dynamic content is being requested, it may not be possible
to perform validation against a list of trusted resources, therefore the list must
also become dynamic (updated as the files change), or perform filtering to remove
extraneous user input (such as semicolons, periods etc.) and only permit `a-z0-9`.

It is also advised that sensitive files are not stored within the web root and
that the user permissions enforced by the directory are correct.
}
            }
        }
    end

end
