=begin
    Copyright 2020-2022 Tasos Laskos <tasos.laskos@gmail.com>

    This file is part of the SCNR::Engine project and is subject to
    redistribution and commercial restrictions. Please see the SCNR::Engine
    web site for more information on licensing and terms of use.
=end

require_relative 'soft_404/handler'

module SCNR::Engine
module HTTP
class Client

# @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
class Soft404
    include UI::Output
    include Utilities
    include MonitorMixin

    prepend Support::Mixins::SpecInstances

    class <<self
        include UI::Output
        personalize_output!
    end

    personalize_output!

    # Maximum size of the cache that holds 404 handler profiles.
    CACHE_SIZE = 0

    def initialize
        super

        @corrupted = Support::Filter::Set.new
        @hard      = Support::Filter::Set.new
        @handlers  = Concurrent::Hash.new

        @handler_runner_queue = Queue.new
        @handlers_done  = Queue.new
        @handlers_done << nil

        # We need to jump out of the callbacks to prevent stack depth errors.
        @handler_runner_thread = Thread.new do
            self.class.consume( self, @handlers_done, @handler_runner_queue )
        end
    end

    def self.consume( sof_404, handlers_done, handler_runner_queue )
        while (handler = handler_runner_queue.pop)
            handlers_done.clear

            begin
                sof_404.synchronize do
                    handler.check do
                        sof_404.corrupted!( handler.url ) if handler.corrupted?
                        sof_404.hard!( handler.url )      if handler.hard?
                    end
                end
            rescue => e
                print_exception e
            ensure
                handlers_done << nil
            end
        end
    end

    # @param  [Response]  response
    #   Checks whether or not the provided response means 'not found'.
    # @param  [Block]   block
    #   To be passed `true` or `false` depending on the result of the analysis.
    #
    # TODO: Cache #match? based on `response.url`.
    def match?( response, &block )
        # This matters, the request URL may differ from the response one due to
        # redirections and we need to test the original.
        url = response.request.url

        if corrupted?( url )
            print_debug "[corrupted]: #{handler_url_for( url )} #{url} #{block}"
            return
        end

        handler = handler_for( url )
        waiting = handler.has_pending_checks?

        handler.schedule_check( response, &block )
        return if waiting

        schedule_handler handler

        nil
    end

    def wait
        sleep 0.1 until @handler_runner_queue.empty? &&
                            !@handlers_done.empty?
        nil
    end

    # @param    [String]    url
    #   URL to check.
    #
    # @return   [Bool]
    # #
    #   * `true` if the `url` is served by a hard-404.
    #   * `false` if the `url` is served by a soft-404.
    #   * `nil` if the 404 for the `url` hasn't been checked yet.
    def hard?( url )
        @hard.include? handler_url_for( url )
    end

    def corrupted?( url )
        @corrupted.include? handler_url_for( url )
    end

    # @private
    def handlers
        @handlers
    end

    # @private
    def prune
        return if @handlers.size <= CACHE_SIZE

        if CACHE_SIZE == 0
            @handlers.clear
            return
        end

        @handlers.keys.each do |k|
            # We've done enough...
            return if @handlers.size <= CACHE_SIZE

            @handlers.delete( k )
        end

        nil
    end

    # @private
    def shutdown
        if @handler_runner_thread
            @handler_runner_thread.kill
        end

        if @handler_runner_queue
            @handler_runner_queue.clear
        end

        if @handlers_done
            @handlers_done.clear
        end

        @hard                  = nil
        @handlers              = nil
        @handler_runner_thread = nil
        @handler_runner_queue  = nil
        @handler_runner_thread = nil
    end

    # @private
    def schedule_handler( url )
        @handler_runner_queue << url
    end

    def corrupted!( url )
        @corrupted << url
    end

    def hard!( url )
        @hard << url
    end

    private

    def handler_for( url )
        @handlers[handler_url_for( url ).hash] ||= Handler.for( self, url )
    end

    def handler_url_for( url )
        Handler.url_for( url )
    end

    def self.info
        { name: 'Soft404' }
    end

    def self._spec_instance_cleanup( i )
        i.shutdown
    end

end
end
end
end
