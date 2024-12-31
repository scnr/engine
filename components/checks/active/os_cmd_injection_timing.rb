=begin
    Copyright 2024 Ecsypno Single Member P.C.

    This file is part of the SCNR::Engine project and is subject to
    redistribution and commercial restrictions. Please see the SCNR::Engine
    web site for more information on licensing and terms of use.
=end

# OS command injection check using timing attacks.
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
#
# @see http://cwe.mitre.org/data/definitions/78.html
# @see https://www.owasp.org/index.php/OS_Command_Injection
class SCNR::Engine::Checks::OsCmdInjectionTiming < SCNR::Engine::Check::Base

    prefer :os_cmd_injection

    OPTIONS = {
        format:          [Format::STRAIGHT],
        timeout:         4000,
        timeout_divider: 1000,
        timeout_add:     -1000,
        each_mutation: proc do |mutation|
            mutation.audit_options[:submit] ||= {}
            if mutation.affected_input_value.include? 'sleep'
                mutation.audit_options[:submit][:data_flow_taint] = 'sleep'
            elsif mutation.affected_input_value.include? 'ping'
                mutation.audit_options[:submit][:data_flow_taint] = 'ping'
            end
        end
    }

    def self.payloads
        @payloads ||= {
            unix:    'sleep __TIME__ #',
            windows: 'ping -n __TIME__ localhost &rem'
        }.inject({}) do |h, (platform, payload)|
            h.merge platform => ['', '\'', '"'].map { |q| "#{q}; #{payload}" }
        end
    end

    def run
        audit_timeout self.class.payloads, OPTIONS
    end

    def self.info
        {
            name:        'OS command injection (timing)',
            description: %q{
Tries to find operating system command injections using timing attacks.
},
            elements:    ELEMENTS_WITH_INPUTS,
            author:      'Tasos "Zapotek" Laskos <tasos.laskos@gmail.com> ',
            version:     '0.4.0',
            sink:        {
              areas: [:blind]
            },
            cost:        calculate_timeout_analysis_cost( payloads.values.flatten.size, OPTIONS ),
            platforms:   payloads.keys,

            issue:       {
                name:            %q{Operating system command injection (timing attack)},
                description:     %q{
To perform specific actions from within a web application, it is occasionally
required to run Operating System commands and have the output of these commands
captured by the web application and returned to the client.

OS command injection occurs when user supplied input is inserted into one of these
commands without proper sanitisation and is then executed by the server.

Cyber-criminals will abuse this weakness to perform their own arbitrary commands
on the server. This can include everything from simple `ping` commands to map the
internal network, to obtaining full control of the server.

By injecting OS commands that take a specific amount of time to execute, SCNR::Engine
was able to detect time based OS command injection. This indicates that proper
input sanitisation is not occurring.
},
                references:  {
                    'OWASP' => 'https://www.owasp.org/index.php/OS_Command_Injection'
                },
                tags:            %w(os command code injection timing blind),
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
}
            }
        }
    end

end
