=begin
    Copyright 2024 Ecsypno Single Member P.C.

    This file is part of the SCNR::Engine project and is subject to
    redistribution and commercial restrictions. Please see the SCNR::Engine
    web site for more information on licensing and terms of use.
=end

class SCNR::Engine::Checks::ExternalServiceInteraction < SCNR::Engine::Check::Base

  def self.payloads
    @payloads ||= [
      "#{SCNR::Engine::Options.check_server.sub( 'http', 'hTtP' )}/#{Utilities.random_seed}/ping",
      "#{SCNR::Engine::Options.check_server}/#{Utilities.random_seed}/ping",
      "#{SCNR::Engine::URI( SCNR::Engine::Options.check_server ).domain}/#{Utilities.random_seed}/ping"
    ]
  end

  def self.options
    @options ||= {
      format:     [Format::STRAIGHT],
      submit:     {
        follow_location: false,
        data_flow_taint: SCNR::Engine::URI( SCNR::Engine::Options.check_server ).domain
      },
      each_mutation: proc do |mutation|
        mutation.affected_input_value = "#{mutation.affected_input_value}/#{mutation.coverage_hash}"
      end
    }
  end

  def run
    audits = {}
    audit self.class.payloads, self.class.options do |response, mutation|
      audits[mutation.coverage_hash] = {
        response: response,
        mutation: mutation
      }
    end

    http.after_run do
      http.get "#{SCNR::Engine::Options.check_server}/#{Utilities.random_seed}" do |response|
        next if response.body.empty?

        hits = nil
        begin
          hits = ::JSON.load( response.body ) || {}
        rescue => e
          # print_exception( e )
          next
        end

        hits.each do |coverage_hash, _|
          next if !(audit = audits[coverage_hash.to_i])

          log(
            response: audit[:response],
            vector:   audit[:mutation]
          )
        end
      end
    end
  end

  def self.info
    {
      name:        'External service interaction',
      description: %q{
Injects a remote URL in all available inputs and checks for pings to the check server.
},

      elements:    ELEMENTS_WITH_INPUTS - [Element::LinkTemplate],
      author:      'Tasos "Zapotek" Laskos <tasos.laskos@gmail.com> ',
      version:     '0.1',
      sink:        {
        areas: [:blind]
      },
      cost:        calculate_signature_analysis_cost( payloads.size, options ),

      issue:       {
        name:        %q{External service interaction},
        description:     %q{
External service interaction arises when it is possible to induce an application to interact with an arbitrary external
service, such as a web or mail server. The ability to trigger arbitrary external service interactions does not constitute
a vulnerability in its own right, and in some cases might even be the intended behavior of the application.

However, in many cases, it can indicate a vulnerability with serious consequences.

The ability to send requests to other systems can allow the vulnerable server to be used as an attack proxy.
By submitting suitable payloads, an attacker can cause the application server to attack other systems that it can interact with.
This may include public third-party systems, internal systems within the same organization, or services available on the
local loopback adapter of the application server itself. Depending on the network architecture, this may expose highly
vulnerable internal services that are not otherwise accessible to external attackers.
},
        cwe:        918,
        severity:        Severity::HIGH,
        remedy_guidance: %q{
You should review the purpose and intended use of the relevant application functionality, and determine whether the
ability to trigger arbitrary external service interactions is intended behavior. If so, you should be aware of the types
of attacks that can be performed via this behavior and take appropriate measures. These measures might include blocking
network access from the application server to other internal systems, and hardening the application server itself to
remove any services available on the local loopback adapter.

If the ability to trigger arbitrary external service interactions is not intended behavior, then you should implement a
whitelist of permitted services and hosts, and block any interactions that do not appear on this whitelist.

Out-of-Band Application Security Testing (OAST) is highly effective at uncovering high-risk features, to the point where
finding the root cause of an interaction can be quite challenging. To find the source of an external service interaction,
try to identify whether it is triggered by specific application functionality, or occurs indiscriminately on all requests.
If it occurs on all endpoints, a front-end CDN or application firewall may be responsible, or a back-end analytics system
parsing server logs. In some cases, interactions may originate from third-party systems; for example, a HTTP request may
trigger a poisoned email which passes through a link-scanner on its way to the recipient.
}
      }
    }
  end

end
