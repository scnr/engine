=begin
    Copyright 2024 Ecsypno Single Member P.C.

    This file is part of the SCNR::Engine project and is subject to
    redistribution and commercial restrictions. Please see the SCNR::Engine
    web site for more information on licensing and terms of use.
=end

# Simple OS command injection check.
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
#
# @see http://cwe.mitre.org/data/definitions/78.html
# @see https://www.owasp.org/index.php/OS_Command_Injection
class SCNR::Engine::Checks::OsCmdInjection < SCNR::Engine::Check::Base

    def self.options
        @options ||= {
            signatures: {
                unix:    [ FILE_SIGNATURES['passwd'] ],
                windows: FILE_SIGNATURES_PER_PLATFORM[:windows]
            },
            format: [Format::STRAIGHT],
            each_mutation: proc do |mutation|
                unix    = '/bin/cat'
                windows = 'type %'

                mutation.audit_options[:submit] ||= {}
                if mutation.affected_input_value.include? unix
                    mutation.audit_options[:submit][:data_flow_taint] = unix
                elsif mutation.affected_input_value.include? windows
                    mutation.audit_options[:submit][:data_flow_taint] = windows
                end
            end
        }
    end

    def self.payloads
        @payloads ||= {
            #                  Linux       BSD                  AIX
            unix:    '/bin/cat /etc/passwd /etc/security/passwd /etc/master.passwd #',
            windows: 'type %SystemDrive%\\\\boot.ini %SystemRoot%\\\\win.ini &rem'
        }.inject({}) do |h, (platform, payload)|
            h.merge platform => ['', '\'', '"'].map { |q| ["#{payload}", "#{q}; #{payload}" ] }.flatten
        end
    end

    def run
        audit self.class.payloads, self.class.options
    end

    def self.info
        {
            name:        'OS command injection',
            description: %q{
Tries to find Operating System command injections.
},
            elements:    ELEMENTS_WITH_INPUTS,
            sink:        {
              areas: [:active]
            },
            cost:        calculate_signature_analysis_cost( payloads.values.flatten.size, options ),
            author:      'Tasos "Zapotek" Laskos <tasos.laskos@gmail.com> ',
            version:     '0.3.0',
            platforms:   payloads.keys,

            issue:       {
                name:            %q{Operating system command injection},
                description:     %q{
To perform specific actions from within a web application, it is occasionally
required to run Operating System commands and have the output of these commands
captured by the web application and returned to the client.

OS command injection occurs when user supplied input is inserted into one of these
commands without proper sanitisation and is then executed by the server.

Cyber-criminals will abuse this weakness to perform their own arbitrary commands
on the server. This can include everything from simple `ping` commands to map the
internal network, to obtaining full control of the server.

SCNR::Engine was able to inject specific Operating System commands and have the output
from that command contained within the server response. This indicates that proper
input sanitisation is not occurring.
},
                references:  {
                    'OWASP' => 'https://www.owasp.org/index.php/OS_Command_Injection',
                    'WASC'  => 'http://projects.webappsec.org/w/page/13246950/OS%20Commanding'
                },
                tags:            %w(os command code injection regexp error),
                cwe:             78,
                severity:        Severity::HIGH,
                remedy_guidance: %q{
It is recommended that untrusted data is never used to form a command to be
executed by the OS.

To validate data, the application should ensure that the supplied value contains
only the characters that are required to perform the required action.

For example, where the form field expects an IP address, only numbers and periods
should be accepted. Additionally, all control operators (`&`, `&&`, `|`, `||`,
`$`, `\`, `#`) should be explicitly denied and never accepted as valid input by
the server.
},
            }
        }
    end

end
