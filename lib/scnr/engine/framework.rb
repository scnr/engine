# encoding: utf-8

=begin
    Copyright 2020 Tasos Laskos <tasos.laskos@gmail.com>

    This file is part of the SCNR::Engine project and is subject to
    redistribution and commercial restrictions. Please see the SCNR::Engine
    web site for more information on licensing and terms of use.
=end

require 'rubygems'
require 'monitor'
require 'bundler/setup'

require_relative 'options'

module SCNR::Engine

lib = Options.paths.lib
require lib + 'support/mixins/spec_instances'
require lib + 'version'
require lib + 'support'
require lib + 'ruby'
require lib + 'error'
require lib + 'scope'
require lib + 'utilities'
require lib + 'uri_common/scope'
require lib + 'platform'
require lib + 'http'
require lib + 'snapshot'
require lib + 'parser'
require lib + 'issue'
require lib + 'check'
require lib + 'plugin'
require lib + 'report'
require lib + 'reporter'
require lib + 'session'
require lib + 'trainer'
require lib + 'browser_cluster'

# The Framework class ties together all the subsystems.
#
# It's the brains of the operation, it bosses the rest of the subsystems around.
# It loads checks, reports and plugins and runs them according to user options.
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
class Framework
    include Singleton

    class <<self

        def method_missing( sym, *args, &block )
            if instance.respond_to?( sym )
                instance.send( sym, *args, &block )
            else
                super( sym, *args, &block )
            end
        end

        def respond_to?( *args )
            super || instance.respond_to?( *args )
        end

    end

    include UI::Output
    include Utilities

    prepend Support::Mixins::SpecInstances
    include Support::Mixins::Parts

    # {Framework} error namespace.
    #
    # All {Framework} errors inherit from and live under it.
    #
    # When I say Framework I mean the {Framework} class, not the entire Engine
    # Framework.
    #
    # @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
    class Error < SCNR::Engine::Error
    end

    # Starts the scan.
    #
    # @param   [Block]  block
    #   A block to call after the audit has finished but before running {#reporters}.
    def run( &block )
        prepare
        handle_signals
        return if aborted?

        # Catch exceptions so that if something breaks down or the user opted to
        # exit the reporters will still run with whatever results Engine managed
        # to gather.
        exception_jail( false ){ audit }

        if aborted? || suspended? || timed_out?
            exception_jail( false ){ block.call } if block_given?
            return
        end

        clean_up
        exception_jail( false ){ block.call } if block_given?

        state.status = :done

        true
    end

    # @return   [Hash]
    #
    #   Framework statistics:
    #
    #   *  `:http`          -- {HTTP::Client#statistics}
    #   * `browser_cluster` -- {BrowserCluster.statistics}
    #   *  `:runtime`       -- Scan runtime in seconds.
    #   *  `:found_pages`   -- Number of discovered pages.
    #   *  `:audited_pages` -- Number of audited pages.
    #   *  `:current_page`  -- URL of the currently audited page.
    #   *  `:status`        -- {#status}
    #   *  `:messages`      -- {#status_messages}
    def statistics
        {
            http:            http.statistics,
            browser_cluster: BrowserCluster.statistics,
            runtime:         @start_datetime ? (@finish_datetime || Time.now) - @start_datetime : 0,
            found_pages:     sitemap.size,
            audited_pages:   state.audited_page_count,
            current_page:    @current_url
        }
    end

    def inspect
        stats = statistics

        s = "#<#{self.class} (#{status}) "

        s << "runtime=#{stats[:runtime]} "
        s << "found-pages=#{stats[:found_pages]} "
        s << "audited-pages=#{stats[:audited_pages]} "
        s << "issues=#{Data.issues.size} "

        if @current_url
            s << "current_url=#{@current_url.inspect} "
        end

        s << "checks=#{@checks.keys.join(',')} "
        s << "plugins=#{@plugins.keys.join(',')}"
        s << '>'
    end

    # @return    [String]
    #   Returns the version of the framework.
    def version
        SCNR::Engine::VERSION
    end

    def self._spec_instance_cleanup( i )
        i.clean_up
        i.reset
    end

    def unsafe
        self
    end

    def safe( &block )
        raise ArgumentError, 'Missing block.' if !block_given?

        begin
            block.call self
        ensure
            clean_up
            reset
        end

        nil
    end
end

end
