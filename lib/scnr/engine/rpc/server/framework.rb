=begin
    Copyright 2020 Tasos Laskos <tasos.laskos@gmail.com>

    This file is part of the SCNR::Engine project and is subject to
    redistribution and commercial restrictions. Please see the SCNR::Engine
    web site for more information on licensing and terms of use.
=end

require 'tempfile'

module SCNR::Engine

lib = Options.paths.lib
require lib + 'framework'
require lib + 'rpc/server/check/manager'
require lib + 'rpc/server/plugin/manager'

module RPC
class Server

# Wraps the framework of the local instance and the frameworks of all its slaves
# (when it is a Master in multi-Instance mode) into a neat, easy to handle package.
#
# @note Ignore:
#
#   * Inherited methods and attributes -- only public methods of this class are
#       accessible over RPC.
#   * `block` parameters, they are an RPC implementation detail for methods which
#       perform asynchronous operations.
#
# @private
# @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
class Framework < ::SCNR::Engine::Framework
    include Utilities

    # {RPC::Server::Framework} error namespace.
    #
    # All {RPC::Server::Framework} errors inherit from and live under it.
    #
    # @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
    class Error < SCNR::Engine::Framework::Error
    end

    # Make these inherited methods public again (i.e. accessible over RPC).
    [ :statistics, :version, :status, :report_as, :list_platforms, :list_platforms,
      :sitemap ].each do |m|
        private m
        public  m
    end

    def initialize( * )
        super

        # Override standard framework components with their RPC-server counterparts.
        @checks  = Check::Manager.new( self )
        @plugins = Plugin::Manager.new( self )

        @extended_running = false
    end

    # @return   [Report]
    #   {Report#to_rpc_data}
    def report( &block )
        # If a block is given it means the call was form an RPC client.
        if block_given?
            block.call super.to_rpc_data
            return
        end

        super
    end

    # @return (see SCNR::Engine::Framework#list_plugins)
    def list_plugins
        super.map do |plugin|
            plugin[:options] = plugin[:options].map(&:to_h)
            plugin
        end
    end

    # @return (see SCNR::Engine::Framework#list_reporters)
    def list_reporters
        super.map do |reporter|
            reporter[:options] = reporter[:options].map(&:to_h)
            reporter
        end
    end

    # @return (see SCNR::Engine::Framework#list_checks)
    def list_checks
        super.map do |check|
            check[:issue][:severity] = check[:issue][:severity].to_s
            check
        end
    end

    # @return   [Bool]
    #   `true` If the system is scanning, `false` if {#run} hasn't been called
    #   yet or if the scan has finished.
    def busy?( &block )
        # If we have a block it means that it was called via RPC, so use the
        # status variable to determine if the scan is done.
        if block_given?
            block.call @extended_running
            return
        end

        !!@extended_running
    end

    # @param    [Integer]   from_index
    #   Get sitemap entries after this index.
    #
    # @return   [Hash<String=>Integer>]
    def sitemap_entries( from_index = 0 )
        return {} if sitemap.size <= from_index + 1

        Hash[sitemap.to_a[from_index..-1] || {}]
    end

    # Starts the scan.
    #
    # @return   [Bool]
    #   `false` if already running, `true` otherwise.
    def run
        # Return if we're already running.
        return false if busy?

        @extended_running = true

        # Start the scan  -- we can't block the RPC server so we're using a Thread.
        Thread.new do
            super
        end

        true
    end

    # If the scan needs to be aborted abruptly this method takes care of any
    # unfinished business (like signaling running plug-ins to finish).
    #
    # Should be called before grabbing the {#report}, especially when running
    # in multi-Instance mode, as it will take care of merging the plug-in results
    # of all instances.
    #
    # You don't need to call this if you've let the scan complete.
    def clean_up( &block )
        if @rpc_cleaned_up
            # Don't shutdown the BrowserCluster here, its termination will be
            # handled by Instance#shutdown.
            block.call false if block_given?
            return false
        end

        @rpc_cleaned_up   = true
        @extended_running = false

        r = super( false )

        if !block_given?
            state.status = :done
            return r
        end

        state.status = :done
        block.call r
    end

    # @return  [Array<Hash>]
    #   Issues as {Engine::Issue#to_rpc_data RPC data}.
    #
    # @private
    def issues
        Data.issues.sort.map(&:to_rpc_data)
    end

    # @return   [Array<Hash>]
    #   {#issues} as an array of Hashes.
    #
    # @see #issues
    def issues_as_hash
        Data.issues.sort.map(&:to_h)
    end

    # @param    [Integer]   starting_line
    #   Sets the starting line for the range of errors to return.
    #
    # @return   [Array<String>]
    def errors( starting_line = 0 )
        return [] if self.error_buffer.empty?

        error_strings = self.error_buffer

        if starting_line != 0
            error_strings = error_strings[starting_line..-1]
        end

        error_strings
    end

    # Provides aggregated progress data.
    #
    # @param    [Hash]  opts
    #   Options about what data to include:
    # @option opts [Bool] :slaves   (true)
    #   Slave statistics.
    # @option opts [Bool] :issues   (true)
    #   Issue summaries.
    # @option opts [Bool] :statistics   (true)
    #   Master/merged statistics.
    # @option opts [Bool, Integer] :errors   (false)
    #   Logged errors. If an integer is provided it will return errors past that
    #   index.
    # @option opts [Bool, Integer] :sitemap   (false)
    #   Scan sitemap. If an integer is provided it will return entries past that
    #   index.
    # @option opts [Bool] :as_hash  (false)
    #   If set to `true`, will convert issues to hashes before returning them.
    #
    # @return    [Hash]
    #   Progress data.
    def progress( opts = {}, &block )
        opts = opts.my_symbolize_keys

        include_statistics = opts[:statistics].nil? ? true : opts[:statistics]
        include_issues     = opts[:issues].nil?     ? true : opts[:issues]
        include_sitemap    = opts.include?( :sitemap ) ?
            (opts[:sitemap] || 0) : false
        include_errors     = opts.include?( :errors ) ?
            (opts[:errors] || 0) : false

        as_hash = opts[:as_hash] ? true : opts[:as_hash]

        data = {
            status:         status,
            busy:           running?,
            seed:           Utilities.random_seed,
            dispatcher_url: @options.dispatcher.url,
            queue_url:      @options.queue.url
        }

        if include_issues
            data[:issues] = as_hash ? issues_as_hash : issues
        end

        if include_statistics
            data[:statistics] = self.statistics
        end

        if include_sitemap
            data[:sitemap] =
                sitemap_entries( include_sitemap.is_a?( Integer ) ? include_sitemap : 0 )
        end

        if include_errors
            data[:errors] =
                errors( include_errors.is_a?( Integer ) ? include_errors : 0 )
        end

        block.call data.merge( messages: status_messages )
    end

    # @private
    def error_test( str, &block )
        print_error str.to_s
        block.call
    end

end

end
end
end
