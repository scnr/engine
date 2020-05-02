=begin
    Copyright 2020 Alex Douckas <alexdouckas@gmail.com>, Tasos Laskos <tasos.laskos@gmail.com>

    This file is part of the SCNR::Engine project and is subject to
    redistribution and commercial restrictions. Please see the SCNR::Engine
    web site for more information on licensing and terms of use.
=end

module SCNR::Engine

# The namespace under which all checks exist.
module Checks
end

module Check

# Manages and runs {Checks} against {Page}s.
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
class Manager < SCNR::Engine::Component::Manager

    # Namespace under which all checks reside.
    NAMESPACE = ::SCNR::Engine::Checks

    # {Manager} error namespace.
    #
    # All {Manager} errors inherit from and live under it.
    #
    # @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
    class Error < Error

        # Raised when a loaded check targets invalid platforms.
        #
        # @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
        class InvalidPlatforms < Error
        end

        # Raised when a loaded check specifies sinks without valid elements.
        #
        # @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
        class InvalidElements < Error
        end

        # Raised when a loaded check specifies an invalid sink.
        #
        # @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
        class InvalidSink < Error
        end

        # Raised when a loaded check specifies an invalid sink.
        #
        # @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
        class MissingCost < Error
        end
    end

    # @param    [SCNR::Engine::Framework]  framework
    def initialize( framework )
        self.class.reset

        @framework = framework
        super( @framework.options.paths.checks, NAMESPACE )
    end

    # @param    [SCNR::Engine::Page]   page
    #   Page to audit.
    def run( page )
        schedule.each { |mod| exception_jail( false ){ run_one( mod, page ) } }
    end

    def on_load( check )
        if !Platform::Manager.valid?( check.platforms )
            unload check.shortname
            fail Error::InvalidPlatforms,
                 "Check #{check.shortname} contains invalid platforms: #{check.platforms.join(', ')}"
        end

        if check.sink
            type_count   = 0
            element_type = nil

            if (check.elements & check::DOM_ELEMENTS_WITH_INPUTS).any?
                type_count  += 1
                element_type = Element::DOM
            end

            if (check.elements & check::ELEMENTS_WITH_INPUTS).any?
                type_count  += 1
                element_type = Element
            end

            if !element_type
                fail Error::InvalidElements,
                     'Checks with :sink need to specify :elements.'
            end

            if type_count > 1
                fail Error::InvalidElements,
                     'Checks with :sink cannot audit both DOM and non-DOM elements.'
            end

            check.sink_areas.each do |sink|
                begin
                    element_type::Capabilities::WithSinks::Sinks.enable sink
                rescue element_type::Capabilities::WithSinks::Sinks::Error::InvalidSink
                    unload name
                    fail Error::InvalidSink,
                         "Check #{name} specifies invalid sink: #{sink}"
                end
            end

            if check.sink_seed
                element_type::Capabilities::WithSinks::Sinks.add_to_extra_seed check.sink_seed
            end

            if check.cost
                element_type::Capabilities::WithSinks::Sinks.add_to_max_cost check.cost
            else
                fail Error::MissingCost, 'Checks with :sink need to specify :cost.'
            end

        end

    end

    # @return   [Array]
    #   Checks in proper running order, taking account their declared
    #   {Check::Base.prefer preferences}.
    def schedule
        schedule       = Set.new
        preferred_over = Hash.new([])

        preferred = self.reject do |name, klass|
            preferred_over[name] = klass.preferred if klass.preferred.any?
        end

        return self.values if preferred_over.empty? || preferred.empty?

        preferred_over.size.times do
            update = {}
            preferred.each do |name, klass|
                schedule << klass
                preferred_over.select { |_, v| v.include?( name.to_sym ) }.each do |k, v|
                    schedule << (update[k] = self[k])
                end
            end

            preferred.merge!( update )
        end

        schedule |= preferred_over.keys.map { |n| self[n] }

        schedule.to_a
    end

    # @return   [Hash]
    #   Checks targeting specific platforms.
    def with_platforms
        select { |k, v| v.has_platforms? }
    end

    # @return   [Hash]
    #   Platform-agnostic checks.
    def without_platforms
        select { |k, v| !v.has_platforms? }
    end

    def without_platforms_nor_sinks
        select { |k, v| !v.has_platforms? && !v.has_sinks? }
    end

    # Runs a single `check` against `page`.
    #
    # @param    [Check::Base]   check
    #   Check to run as a class.
    # @param    [Page]   page
    #   Page to audit.
    #
    # @return   [Bool]
    #   `true` if the check was ran (based on {Check::Auditor.check?}),
    #   `false` otherwise.
    def run_one( check, page )
        return false if !check.check?( page )

        check_new = check.new( page, @framework )
        check_new.prepare
        check_new.run
        check_new.clean_up

        true
    end

    def self.reset
        remove_constants( NAMESPACE )
    end
    def reset
        self.class.reset
    end

end
end
end
