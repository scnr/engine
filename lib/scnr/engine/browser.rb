=begin
    Copyright 2020 Tasos Laskos <tasos.laskos@gmail.com>

    This file is part of the SCNR::Engine project and is subject to
    redistribution and commercial restrictions. Please see the SCNR::Engine
    web site for more information on licensing and terms of use.
=end

module SCNR::Engine

# Real browser driver providing DOM/JS/AJAX support.
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
class Browser
    include Utilities
    include UI::Output
    personalize_output!

    include Support::Mixins::Observable
    prepend Support::Mixins::SpecInstances

    # {Browser} error namespace.
    #
    # All {Browser} errors inherit from and live under it.
    #
    # @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
    class Error < SCNR::Engine::Error
    end

    require_relative 'browser/parse_profile'
    require_relative 'browser/javascript'
    require_relative 'browser/engines'

    include Support::Mixins::Parts

    # @return   [Hash]
    attr_reader :options

    # @return   [Javascript]
    attr_reader :javascript

    def self.reset
        asset_domains.clear
    end

    # @param    [Hash]  options
    # @option options   [Integer]    :concurrency
    #   Maximum number of concurrent connections.
    # @option   options [Bool] :store_pages  (true)
    #   Whether to store pages in addition to just passing them to {#on_new_page}.
    # @option   options [Symbol] :engine
    #   Filename, as symbol, of one of {Engines}.
    # @option   options [Integer] :width  (1600)
    #   Window width -- Firefox minimum seems to be 300px.
    #   TODO: Raise error or unsupported value.
    # @option   options [Integer] :height  (1200)
    #   Window height -- Firefox minimum seems to be 101px.
    #   TODO: Raise error or unsupported value.
    def initialize( options = {} )
        @options = options.dup

        @window_responses = {}

        super()

        @javascript = Javascript.new( self )
    end

    def shutdown
        print_debug 'Shutting down...'

        engine.shutdown if @engine
        @engine = nil

        clear_buffers

        print_debug '...shutdown complete.'
    end

    def inspect
        s = "#<#{self.class} "
        s << "engine_lifeline_pid=#{engine.lifeline_pid} "
        s << "engine_pid=#{engine.pid} "
        s << "last-url=#{@last_url.inspect} "
        s << "transitions=#{@transitions.size}"
        s << '>'
    end

    private

    def clear_buffers
        @preloads.clear
        @captured_pages.clear
        @page_snapshots.clear
        @page_snapshots_with_sinks.clear
        @window_responses.clear
    end

    def skip_path?( path )
        enforce_scope? && super( path )
    end

    def self._spec_instance_cleanup( i )
        i.shutdown
    end

end
end
