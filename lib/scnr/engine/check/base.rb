=begin
    Copyright 2020 Tasos Laskos <tasos.laskos@gmail.com>

    This file is part of the SCNR::Engine project and is subject to
    redistribution and commercial restrictions. Please see the SCNR::Engine
    web site for more information on licensing and terms of use.
=end

module SCNR::Engine

require Options.paths.lib + 'check/auditor'

module Check

# Base check class to be extended by all checks.
#
# Defines basic structure and provides utilities to checks.
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
# @abstract
class Base < Component::Base
    include SCNR::Engine
    include Component::Output
    include Auditor
    include Utilities

    # def self.included( check )
    #     check.personalize_output!
    # end

    # @param  [Page]    page
    def initialize( page )
        super
    end

    # OPTIONAL
    #
    # It provides you with a way to setup your check's data and methods.
    #
    # @abstract
    def prepare
    end

    # REQUIRED
    #
    # This is used to deliver the check's payload whatever it may be.
    #
    # @abstract
    def run
    end

    # OPTIONAL
    #
    # This is called after {#run} has finished executing,
    #
    # @abstract
    def clean_up
    end

    def preferred
        self.class.preferred
    end

    # REQUIRED
    #
    # Provides information about the check.
    # Don't take this lightly and don't ommit any of the info.
    #
    # @abstract
    def self.info
        {
            name:        'Base check abstract class',
            description: %q{Provides an abstract class the check should implement.},
            #
            # SCNR::Engine needs to know what elements the check plans to audit
            # before invoking it.
            # If a page doesn't have any of those elements
            # there's no point in instantiating the check.
            #
            # If you want the check to run no-matter what, leave the array
            # empty.
            #
            # elements: [
            #     Element::Form,
            #     Element::Link
            #     Element::Cookie
            #     Element::Header
            # ],
            elements:    [],
            author:      'Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>',
            version:     '0.1',
            references:  {
                'Title' => 'http://ref.url'
            },

            issue:       {
                name:           %q{Serious issue},
                description:    %q{This issue is a serious issue and you
                    should consider it seriously},
                # CWE ID number
                cwe:            0,
                #
                # Severity can be:
                #
                # Severity::HIGH
                # Severity::MEDIUM
                # Severity::LOW
                # Severity::INFORMATIONAL
                #
                severity:        Severity::HIGH,
                remedy_guidance: %q{Paint it blue and throw it in the sea.},
                remedy_code:     %q{sudo rm -rf /}
            }
        }
    end

    class <<self

        # @return   [Bool]
        #   `true` if the check can benefit from knowing the platform beforehand,
        #   `false` otherwise.
        #
        # @see .platforms
        def has_platforms?
            platforms.any?
        end

        # @return   [Array<Symbol>]
        #   Targeted platforms.
        #
        # @see .info
        def platforms
            @platforms ||= [info[:platforms]].flatten.compact
        end

        # @return   [Bool]
        #   `true` if the check has specified platforms for which it does not apply.
        #
        # @see .platforms
        def has_exempt_platforms?
            exempt_platforms.any?
        end

        # @return   [Array<Symbol>]
        #   Platforms not applicable to this check.
        #
        # @see .info
        def exempt_platforms
            @exempt_platforms ||= [info[:exempt_platforms]].flatten.compact
        end

        # @param    [Array<Symbol, String>]     resource_platforms
        #   List of platforms to check for support.
        #
        # @return   [Boolean]
        #   `true` if any of the given platforms are supported, `false` otherwise.
        def supports_platforms?( resource_platforms )
            if resource_platforms.any? && has_exempt_platforms?
                manager = Platform::Manager.new( exempt_platforms )

                resource_platforms.each do |p|

                    # When we check for exempt platforms we're looking for info
                    # from the same type.
                    ptype = Platform::Manager.find_type( p )
                    type_manager = manager.send( ptype )

                    return false if type_manager.pick( p => true ).any?
                end
            end

            return true if resource_platforms.empty? || !has_platforms?

            # Determine if we've got anything for the given platforms, the same
            # way payloads are picked.
            foo_data = self.platforms.
                inject({}) { |h, platform| h.merge!( platform => true ) }

            Platform::Manager.new( resource_platforms ).pick( foo_data ).any?
        end

        # @return   [Array<Symbol>]
        #   Targeted element types.
        #
        # @see .info
        def elements
            @elements ||= [info[:elements]].flatten.compact
        end

        # Schedules self to be run *after* the specified checks and prevents
        # auditing elements that have been previously logged by any of these checks.
        #
        # @return   [Array]
        #   Check names.
        def prefer( *args )
            @preferred = args.flatten.compact
        end

        # @return   [Array]
        #   Names of checks which should be preferred over this one.
        #
        # @see #prefer
        def preferred
            @preferred ||= []
        end

        def cost
            info[:cost]
        end

        def sink
            info[:sink]
        end

        def sink_seed
            return if !sink
            sink[:seed]
        end

        def sink_areas
            return [] if !sink
            [sink[:areas]].flatten.compact
        end

        def has_sinks?
            sink_areas.any?
        end

        # @param    [Element::Capabilities::WithSinks::Sinks, Element::DOM::Capabilities::WithSinks::Sinks] sinks
        def supports_sinks?( sinks )
            return true if !has_sinks?

            self.sink_areas.each do |sink|
                return true if sinks.send( "#{sink}?" )
            end

            false
        end

        # @private
        def clear_info_cache
            @elements = @exempt_platforms = @platforms = nil
        end
    end

end
end
end
