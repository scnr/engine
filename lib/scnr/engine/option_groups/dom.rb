=begin
    Copyright 2020-2022 Tasos Laskos <tasos.laskos@gmail.com>

    This file is part of the SCNR::Engine project and is subject to
    redistribution and commercial restrictions. Please see the SCNR::Engine
    web site for more information on licensing and terms of use.
=end

module SCNR::Engine::OptionGroups

# Options for the {BrowserPool} and its {BrowserPool::Worker}s.
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
class DOM < SCNR::Engine::OptionGroup

    ENGINES        = [:none, :chrome, :firefox]
    DEFAULT_ENGINE = :chrome

    # @note Default is {#DEFAULT_ENGINE}.
    #
    # @return   [Hash]
    attr_accessor :engine

    # @return   [Hash]
    #   Data to be set in the browser's `localStorage`.
    attr_accessor :local_storage

    # @return   [Hash]
    #   Data to be set in the browser's `sessionStorage`.
    attr_accessor :session_storage

    # @return   [Hash<Regexp,String>]
    #   When the page URL matches the key `Regexp`, wait until the `String` CSS
    #   selector in the value matches an element.
    attr_accessor :wait_for_elements

    # @return   [Integer]
    #   Amount of {BrowserPool::Worker} to keep in the pool and put to work.
    attr_accessor :pool_size

    # @return   [Integer]
    #   Maximum allowed time for jobs in seconds.
    attr_accessor :job_timeout

    # @return   [Integer]
    #   Re-spawn the browser every {#worker_time_to_live} jobs.
    attr_accessor :worker_time_to_live

    # @return   [Bool]
    #   Shall we wait for the max timer to fire on the page?
    attr_accessor :wait_for_timers

    set_defaults(
        engine:              DEFAULT_ENGINE,
        local_storage:       {},
        session_storage:     {},
        wait_for_elements:   {},
        pool_size:           4,

        # Each event may have effects, like a page loading one.
        # Few transitions of clicks and such and we're there.
        job_timeout:         120,

        worker_time_to_live: 1000,

        wait_for_timers:     false
    )

    def wait_for_timers?
        !!@wait_for_timers
    end

    def engine=( e )
        return @engine = defaults[:engine] if !e

        e = e.to_sym

        if !ENGINES.include?( e )
            fail ArgumentError,
                 "Unknown engine: #{e}. Supported engines are: #{ENGINES.join( ', ' )}"
        end

        @engine = e

        if @engine == :none
            disable!
        end

        @engine
    end

    def disable!
        @pool_size = 0
    end

    def enabled?
        !disabled?
    end

    def disabled?
        @pool_size == 0
    end

    def pool_size=( ps )
        return @pool_size = defaults[:pool_size] if !ps

        fail ArgumentError, 'Pool size cannot be negative' if ps.to_i < 0
        @pool_size = ps
    end

    def local_storage=( data )
        data ||= {}

        if !data.is_a?( Hash )
            fail ArgumentError,
                 "Expected data to be Hash, got #{data.class} instead."
        end

        @local_storage = data
    end

    def session_storage=( data )
        data ||= {}

        if !data.is_a?( Hash )
            fail ArgumentError,
                 "Expected data to be Hash, got #{data.class} instead."
        end

        @session_storage = data
    end

    def css_to_wait_for( url )
        wait_for_elements.map do |pattern, css|
            next if !(pattern.match? url)
            css
        end.compact
    end

    def wait_for_elements=( rules )
        return @wait_for_elements = defaults[:wait_for_elements].dup if !rules

        @wait_for_elements = rules.inject({}) do |h, (regexp, value)|
            regexp = regexp.is_a?( Regexp ) ?
                regexp :
                Regexp.new( regexp.to_s, Regexp::IGNORECASE )
            h.merge!( regexp => value )
            h
        end
    end

    def to_rpc_data
        d = super

        d['engine'] = d['engine'].to_s
        d['wait_for_elements'] = d['wait_for_elements'].dup

        d['wait_for_elements'].dup.each do |k, v|
            d['wait_for_elements'][k.source] = d['wait_for_elements'].delete( k )
        end

        d
    end

end
end
